//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Orchestrates event dispatch: groups events by customer, resolves JWTs via AuthManager,
/// and delegates each group to the underlying `OptistreamNetworking` transport.
///
/// Callers receive per-group results via `onGroupResult`, allowing them to handle partial
/// success (e.g. remove successfully sent events from a persistent queue while keeping
/// failed ones for retry).
public protocol OptistreamDispatcher {
    /// Send a batch of events, potentially splitting them by customer identity for auth.
    ///
    /// - Parameters:
    ///   - events: The batch of events to send.
    ///   - path: Optional path appended to the endpoint URL.
    ///   - onGroupResult: Called once per customer group with that group's send result.
    ///     Groups are processed sequentially; the next group starts only after the previous
    ///     one's `onGroupResult` fires.
    ///   - completion: Called once after all groups have been processed.
    func sendBatch(
        events: [OptistreamEvent],
        path: String?,
        onGroupResult: @escaping (_ groupEvents: [OptistreamEvent], _ result: Result<Void, NetworkError>) -> Void,
        completion: @escaping () -> Void
    )
}

public final class OptistreamDispatcherImpl: OptistreamDispatcher {
    private let networking: OptistreamNetworking
    private let authManager: AuthManager?

    public init(
        networking: OptistreamNetworking,
        authManager: AuthManager? = nil
    ) {
        self.networking = networking
        self.authManager = authManager
    }

    public func sendBatch(
        events: [OptistreamEvent],
        path: String?,
        onGroupResult: @escaping (_ groupEvents: [OptistreamEvent], _ result: Result<Void, NetworkError>) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let authManager = authManager else {
            // No auth configured — send the entire batch as-is, no JWT.
            // If the backend returns 401, this is permanent (no AuthManager to produce a JWT).
            networking.send(events: events, path: path, jwt: nil) { result in
                if case .failure(.unauthorized) = result {
                    onGroupResult(events, .failure(.authNotConfigured))
                } else {
                    onGroupResult(events, result)
                }
                completion()
            }
            return
        }

        // Group events by customer identity so each request carries a single JWT.
        // Anonymous events (customer nil) are grouped together and sent without JWT.
        let grouped = Dictionary(grouping: events) { $0.customer }
        let groups = Array(grouped)

        if groups.count <= 1, let first = groups.first {
            // All events belong to the same customer (or all anonymous) — no splitting needed
            sendGroup(
                events: events,
                path: path,
                customerId: first.key,
                authManager: authManager,
                onGroupResult: onGroupResult,
                completion: completion
            )
            return
        }

        // Multiple customers — process groups sequentially
        func processNext(_ index: Int) {
            guard index < groups.count else {
                completion()
                return
            }
            let (customerId, groupEvents) = groups[index]
            sendGroup(
                events: groupEvents,
                path: path,
                customerId: customerId,
                authManager: authManager,
                onGroupResult: onGroupResult
            ) {
                processNext(index + 1)
            }
        }
        processNext(0)
    }

    /// Resolve JWT for a single customer group and send via the networking transport.
    private func sendGroup(
        events: [OptistreamEvent],
        path: String?,
        customerId: String?,
        authManager: AuthManager,
        onGroupResult: @escaping ([OptistreamEvent], Result<Void, NetworkError>) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let customerId = customerId, !customerId.isEmpty else {
            networking.send(events: events, path: path, jwt: nil) { result in
                onGroupResult(events, result)
                completion()
            }
            return
        }

        authManager.getToken(userId: customerId) { [networking] tokenResult in
            switch tokenResult {
            case .success(let jwt):
                networking.send(events: events, path: path, jwt: jwt) { result in
                    onGroupResult(events, result)
                    completion()
                }
            case .failure(let error):
                Logger.error(
                    "Auth token fetch failed for userId '\(customerId)': \(error.localizedDescription)"
                )
                onGroupResult(events, .failure(NetworkError.authFailed(error)))
                completion()
            }
        }
    }
}
