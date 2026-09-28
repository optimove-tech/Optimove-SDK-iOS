//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

/// Deliberately generous: the waits in these tests bound work that has already been forced to
/// happen, so a slow machine can only make them take longer, never change the outcome. A tight
/// bound is what turns a deterministic test back into a flaky one — the suite has been measured
/// taking 11x longer under full CPU load.
private let generousTimeout: TimeInterval = 10

final class AuthManagerTests: XCTestCase {

    // MARK: - 1.1 getToken calls provider with correct userId

    func test_getToken_callsProviderWithUserId() {
        let providerExpectation = expectation(description: "Provider should be called with correct userId")
        let authManager = AuthManager { userId, completion in
            XCTAssertEqual(userId, "user-123")
            providerExpectation.fulfill()
            completion("token", nil)
        }

        authManager.getToken(userId: "user-123") { _ in }
        waitForExpectations(timeout: 1)
    }

    // MARK: - 1.2 getToken returns success when provider returns token

    func test_getToken_returnsSuccessWhenProviderReturnsToken() {
        let completionExpectation = expectation(description: "Completion should receive .success")
        let authManager = AuthManager { _, completion in
            completion("jwt-token", nil)
        }

        authManager.getToken(userId: "user-123") { result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token, "jwt-token")
            case .failure:
                XCTFail("Expected success but got failure")
            }
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - 1.3 getToken returns failure when provider returns error

    func test_getToken_returnsFailureWhenProviderReturnsError() {
        let completionExpectation = expectation(description: "Completion should receive .failure")
        let someError = NSError(domain: "test", code: 42, userInfo: nil)
        let authManager = AuthManager { _, completion in
            completion(nil, someError)
        }

        authManager.getToken(userId: "user-123") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 42)
            }
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - 1.4 getToken returns tokenFetchFailed when provider returns nil token and nil error

    func test_getToken_returnsTokenFetchFailedWhenProviderReturnsNilTokenAndNilError() {
        let completionExpectation = expectation(description: "Completion should receive .failure(tokenFetchFailed)")
        let authManager = AuthManager { _, completion in
            completion(nil, nil)
        }

        authManager.getToken(userId: "user-123") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                guard let authError = error as? AuthError else {
                    XCTFail("Expected AuthError but got \(type(of: error))")
                    completionExpectation.fulfill()
                    return
                }
                XCTAssertEqual(authError, AuthError.tokenFetchFailed)
            }
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: - 1.5 getToken returns timeout when provider does not complete

    func test_getToken_returnsTimeoutWhenProviderDoesNotComplete() {
        let completionExpectation = expectation(description: "Completion should receive .failure(tokenFetchTimedOut)")
        let authManager = AuthManager(tokenFetchTimeout: 0.05) { _, _ in
            // Simulates a tenant token provider that never calls completion.
        }

        authManager.getToken(userId: "user-123") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                guard let authError = error as? AuthError else {
                    XCTFail("Expected AuthError but got \(type(of: error))")
                    completionExpectation.fulfill()
                    return
                }
                XCTAssertEqual(authError, AuthError.tokenFetchTimedOut)
            }
            completionExpectation.fulfill()
        }
        // Unlike the tests above, this one waits on a real timer rather than a synchronous
        // callback, so it gets the generous bound.
        waitForExpectations(timeout: generousTimeout)
    }

    // MARK: - 1.6 getToken ignores provider completion after timeout

    /// The ordering under test — provider answers *after* the timeout — is enforced rather than
    /// raced. The provider holds its token until the test has seen the timeout, so no arrangement
    /// of wall-clock delays can invert the two, however loaded the machine is. Every wait is then
    /// a generous upper bound on something that has already been made to happen, which is what
    /// makes the test deterministic: load can only make it slower, never wrong.
    func test_getToken_ignoresProviderCompletionAfterTimeout() {
        let releaseLateToken = DispatchSemaphore(value: 0)
        let providerAsked = expectation(description: "The provider was asked for a token")
        let firstCompletion = expectation(description: "getToken called its completion")
        let lateTokenDelivered = expectation(description: "The provider delivered its token after the timeout")

        let authManager = AuthManager(tokenFetchTimeout: 0.05) { _, completion in
            providerAsked.fulfill()
            DispatchQueue.global(qos: .utility).async {
                releaseLateToken.wait()
                completion("late-token", nil)
                lateTokenDelivered.fulfill()
            }
        }

        // Record rather than assert inside the callback: a callback that never runs cannot fail a
        // test from the inside, and a second, wrongly delivered call has to be counted to be seen.
        let resultsLock = NSLock()
        var results: [Result<String, Error>] = []

        authManager.getToken(userId: "user-123") { result in
            resultsLock.lock()
            results.append(result)
            let isFirst = results.count == 1
            resultsLock.unlock()

            if isFirst {
                firstCompletion.fulfill()
            }
        }

        wait(for: [providerAsked, firstCompletion], timeout: generousTimeout)

        // The timeout has now been observed, so anything the provider delivers from here is late
        // by construction.
        releaseLateToken.signal()
        wait(for: [lateTokenDelivered], timeout: generousTimeout)

        resultsLock.lock()
        let observed = results
        resultsLock.unlock()

        XCTAssertEqual(observed.count, 1, "The token that arrived after the timeout should have been dropped")

        guard case let .failure(error)? = observed.first else {
            XCTFail("Expected a single timeout failure, got \(observed)")
            return
        }
        XCTAssertEqual(error as? AuthError, AuthError.tokenFetchTimedOut)
    }
}
