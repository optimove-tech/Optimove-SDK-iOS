//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

// MARK: - NetworkClient spy that captures requests

private final class NetworkClientSpy: NetworkClient {
    var lastRequest: NetworkRequest?
    var mockResult: Result<NetworkResponse<Data?>, NetworkError>?

    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {
        lastRequest = request
        if let result = mockResult {
            completion(result)
        }
    }
}

// MARK: - Test event factory

private func makeEvent(customer: String? = nil) -> OptistreamEvent {
    return OptistreamEvent(
        tenant: 9999,
        category: "test",
        event: "test_event",
        origin: "sdk",
        customer: customer,
        visitor: "visitor-1",
        timestamp: "2026-01-01T00:00:00.000Z",
        context: [],
        metadata: OptistreamEvent.Metadata(
            realtime: false,
            firstVisitorDate: 1000,
            eventId: UUID().uuidString,
            requestId: UUID().uuidString
        )
    )
}

// MARK: - Test-only helper to create NetworkResponse (internal init is accessible via @testable)

private func makeSuccessResponse() -> Result<NetworkResponse<Data?>, NetworkError> {
    return .success(NetworkResponse<Data?>(statusCode: 200, body: nil))
}

// MARK: - Tests

final class OptistreamNetworkingTests: XCTestCase {

    private var networkClientSpy: NetworkClientSpy!
    var networking: OptistreamNetworkingImpl!
    let endpoint = URL(string: "https://example.com/optistream")!

    override func setUp() {
        super.setUp()
        networkClientSpy = NetworkClientSpy()
        networking = OptistreamNetworkingImpl(networkClient: networkClientSpy, endpoint: endpoint)
    }

    func test_send_withJWT_includesXUserJWTHeader() {
        let completionExpectation = expectation(description: "completion called")
        networkClientSpy.mockResult = makeSuccessResponse()

        networking.send(events: [makeEvent()], path: nil, jwt: "my-jwt") { _ in
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let headers = networkClientSpy.lastRequest?.headers
        let jwtHeader = headers?.first(where: { $0.field == "X-User-JWT" })
        XCTAssertNotNil(jwtHeader, "Request should include X-User-JWT header")
        XCTAssertEqual(jwtHeader?.value, "my-jwt")
    }

    func test_send_withoutJWT_noUserJWTHeader() {
        let completionExpectation = expectation(description: "completion called")
        networkClientSpy.mockResult = makeSuccessResponse()

        networking.send(events: [makeEvent()], path: nil, jwt: nil) { _ in
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        let headers = networkClientSpy.lastRequest?.headers ?? []
        let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
        XCTAssertNil(jwtHeader, "Request should NOT include X-User-JWT header when jwt is nil")
    }

    func test_send_success_callsCompletionWithSuccess() {
        let completionExpectation = expectation(description: "completion called with success")
        networkClientSpy.mockResult = makeSuccessResponse()

        networking.send(events: [makeEvent()], path: nil, jwt: nil) { result in
            if case .success = result {
                completionExpectation.fulfill()
            } else {
                XCTFail("Expected success")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_send_requestInvalid_callsCompletionWithSuccess() {
        let completionExpectation = expectation(description: "completion called with success on non-401 4xx")
        networkClientSpy.mockResult = .failure(.requestInvalid(nil))

        networking.send(events: [makeEvent()], path: nil, jwt: nil) { result in
            if case .success = result {
                completionExpectation.fulfill()
            } else {
                XCTFail("Expected success on requestInvalid (non-401 4xx should still prune events)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_send_unauthorized_callsCompletionWithFailure() {
        let completionExpectation = expectation(description: "completion called with failure on 401")
        networkClientSpy.mockResult = .failure(.unauthorized(nil))

        networking.send(events: [makeEvent()], path: nil, jwt: nil) { result in
            if case .failure = result {
                completionExpectation.fulfill()
            } else {
                XCTFail("Expected failure on 401 (events should be retried)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_send_networkError_callsCompletionWithFailure() {
        let completionExpectation = expectation(description: "completion called with failure")
        networkClientSpy.mockResult = .failure(.requestFailed)

        networking.send(events: [makeEvent()], path: nil, jwt: nil) { result in
            if case .failure = result {
                completionExpectation.fulfill()
            } else {
                XCTFail("Expected failure on network error")
            }
        }

        waitForExpectations(timeout: 1)
    }
}
