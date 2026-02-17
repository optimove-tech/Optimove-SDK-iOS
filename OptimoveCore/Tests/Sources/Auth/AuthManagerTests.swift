//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

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
}
