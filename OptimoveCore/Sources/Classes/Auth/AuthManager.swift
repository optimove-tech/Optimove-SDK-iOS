//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Closure type that the client app provides to supply JWTs for authenticated requests.
/// - Parameters:
///   - userId: The user identifier to fetch a token for.
///   - completion: Call with `(token, nil)` on success or `(nil, error)` on failure.
public typealias AuthTokenProvider = (
    _ userId: String,
    _ completion: @escaping (_ token: String?, _ error: Error?) -> Void
) -> Void

/// Errors related to auth token fetching.
public enum AuthError: Error, LocalizedError {
    case tokenFetchFailed
    case tokenFetchTimedOut
    case noUserId

    public var errorDescription: String? {
        switch self {
        case .tokenFetchFailed:
            return "Failed to fetch auth token from provider."
        case .tokenFetchTimedOut:
            return "Timed out fetching auth token from provider."
        case .noUserId:
            return "No userId available for auth token request."
        }
    }
}

/// Manages JWT token retrieval from the client-provided closure.
/// - Threading: `getToken` can be called from any queue. The `completion` callback is invoked
///   on the queue the client's `AuthTokenProvider` closure dispatches to, or on a background queue
///   if the provider times out — callers should not assume any specific queue and should dispatch
///   to their target queue if needed.
public final class AuthManager {
    private let provider: AuthTokenProvider
    private let tokenFetchTimeout: TimeInterval

    public init(
        tokenFetchTimeout: TimeInterval = 10,
        provider: @escaping AuthTokenProvider
    ) {
        self.provider = provider
        self.tokenFetchTimeout = tokenFetchTimeout
    }

    /// Request a JWT for the given userId from the client-provided closure.
    /// - Parameters:
    ///   - userId: The user identifier to authenticate.
    ///   - completion: Called with `.success(token)` or `.failure(error)`.
    ///     Invoked on the queue chosen by the client's `AuthTokenProvider`, or on a background queue
    ///     if the provider times out — no specific queue is guaranteed.
    public func getToken(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let lock = NSLock()
        var didComplete = false
        var timeoutWorkItem: DispatchWorkItem?

        func completeOnce(_ result: Result<String, Error>) {
            lock.lock()
            guard !didComplete else {
                lock.unlock()
                return
            }
            didComplete = true
            let workItem = timeoutWorkItem
            timeoutWorkItem = nil
            lock.unlock()
            workItem?.cancel()
            completion(result)
        }

        if tokenFetchTimeout > 0 {
            let workItem = DispatchWorkItem {
                completeOnce(.failure(AuthError.tokenFetchTimedOut))
            }
            lock.lock()
            timeoutWorkItem = workItem
            lock.unlock()
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + tokenFetchTimeout, execute: workItem)
        }

        provider(userId) { token, error in
            if let token = token {
                completeOnce(.success(token))
            } else {
                completeOnce(.failure(error ?? AuthError.tokenFetchFailed))
            }
        }
    }
}

#if swift(>=5.5)
extension AuthManager: @unchecked Sendable {}
#endif
