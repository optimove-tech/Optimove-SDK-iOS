//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

// MARK: - Stub authorization that returns a fixed header

private class StubAuthorization: HttpAuthorizationProtocol {
    func getAuthorizationHeader(strategy: AuthorizationStrategy) throws -> HttpHeader {
        return ["Authorization": "Basic dGVzdDp0ZXN0"]
    }
}

// MARK: - Stub URL Builder with runtime URLs

private class StubUrlBuilder: UrlBuilder {
    convenience init() {
        self.init(storage: KeyValPersistenceHelper.self)
        self.runtimeUrlsMap = [
            .events: "https://test-events.example.com",
            .crm: "https://test-crm.example.com",
            .ddl: "https://test-ddl.example.com",
            .iar: "https://test-iar.example.com",
            .media: "https://test-media.example.com",
            .push: "https://test-push.example.com",
        ]
    }

    required init(storage: KeyValPersistenceHelper.Type) {
        super.init(storage: storage)
    }
}

// MARK: - Tests

final class KSHttpClientTests: XCTestCase {

    func test_sendRequest_authConfigured_getTokenFails_callsOnFailure() {
        let authManager = AuthManager { _, completion in
            completion(nil, NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
        }

        let client = KSHttpClientImpl(
            serviceType: .events,
            urlBuilder: StubUrlBuilder(),
            requestFormat: .json,
            responseFormat: .json,
            authorization: StubAuthorization(),
            authManager: authManager
        )

        let failureExpectation = expectation(description: "onFailure called due to auth token failure")

        client.sendRequest(
            .POST,
            toPath: "/v1/test",
            data: nil,
            authUserId: "user-123",
            onSuccess: { _, _ in
                XCTFail("Expected failure, not success")
            },
            onFailure: { response, error, _ in
                XCTAssertNil(response, "No HTTP response should exist — request was never sent")
                XCTAssertNotNil(error)
                XCTAssertEqual((error as NSError?)?.code, 401)
                failureExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 2)
    }

    func test_sendRequest_authConfigured_success_callsGetTokenWithCorrectUserId() {
        let getTokenExpectation = expectation(description: "getToken called with correct userId")

        let authManager = AuthManager { userId, completion in
            XCTAssertEqual(userId, "user-456")
            getTokenExpectation.fulfill()
            completion("jwt-token-xyz", nil)
        }

        let client = KSHttpClientImpl(
            serviceType: .events,
            urlBuilder: StubUrlBuilder(),
            requestFormat: .json,
            responseFormat: .json,
            authorization: StubAuthorization(),
            authManager: authManager
        )

        client.sendRequest(
            .POST,
            toPath: "/v1/test",
            data: ["key": "value"],
            authUserId: "user-456",
            onSuccess: { _, _ in },
            onFailure: { _, _, _ in }
        )

        waitForExpectations(timeout: 2)
        client.invalidateSessionCancellingTasks(true)
    }
}
