//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

// MARK: - Spy that records (events, path, jwt) per send call

final class OptistreamNetworkingSpy: OptistreamNetworking {
    struct SendCall {
        let events: [OptistreamEvent]
        let path: String?
        let jwt: String?
    }

    var sendCalls: [SendCall] = []
    var sendResult: Result<Void, NetworkError> = .success(())

    func send(events: [OptistreamEvent], path: String?, jwt: String?, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        sendCalls.append(SendCall(events: events, path: path, jwt: jwt))
        completion(sendResult)
    }
}

// MARK: - Test Event Factory

private func makeEvent(customer: String?, event: String = "test") -> OptistreamEvent {
    return OptistreamEvent(
        tenant: 9999,
        category: "test",
        event: event,
        origin: "sdk",
        customer: customer,
        visitor: "visitor-1",
        timestamp: "2026-01-01T00:00:00.000Z",
        context: [],
        metadata: OptistreamEvent.Metadata(
            realtime: true,
            firstVisitorDate: 1000,
            eventId: UUID().uuidString,
            requestId: UUID().uuidString
        )
    )
}

// MARK: - Tests

final class OptistreamDispatcherTests: XCTestCase {

    func test_sendBatch_noAuthManager_sendsEntireBatchWithoutJWT() {
        let networkingSpy = OptistreamNetworkingSpy()
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: nil)

        let events = [makeEvent(customer: "user-A"), makeEvent(customer: "user-B")]

        let completionExpectation = expectation(description: "completion called")
        var groupResults: [(events: [OptistreamEvent], result: Result<Void, NetworkError>)] = []

        dispatcher.sendBatch(
            events: events,
            path: "testPath",
            onGroupResult: { groupEvents, result in
                groupResults.append((groupEvents, result))
            },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 1, "Should send entire batch in one call")
        XCTAssertEqual(networkingSpy.sendCalls.first?.events.count, 2)
        XCTAssertNil(networkingSpy.sendCalls.first?.jwt, "JWT should be nil when no authManager")
        XCTAssertEqual(networkingSpy.sendCalls.first?.path, "testPath")
        XCTAssertEqual(groupResults.count, 1, "onGroupResult should be called once")
    }


    func test_sendBatch_authConfigured_singleCustomer_sendsWithJWT() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { userId, completion in
            XCTAssertEqual(userId, "user-A")
            completion("jwt-for-A", nil)
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [makeEvent(customer: "user-A"), makeEvent(customer: "user-A")]

        let completionExpectation = expectation(description: "completion called")

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { _, _ in },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 1)
        XCTAssertEqual(networkingSpy.sendCalls.first?.jwt, "jwt-for-A")
        XCTAssertEqual(networkingSpy.sendCalls.first?.events.count, 2)
    }


    func test_sendBatch_authConfigured_anonymousEvents_sendsWithoutJWT() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { _, completion in
            XCTFail("getToken should not be called for anonymous events")
            completion(nil, NSError(domain: "test", code: 0))
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [makeEvent(customer: nil), makeEvent(customer: nil)]

        let completionExpectation = expectation(description: "completion called")

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { _, _ in },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 1)
        XCTAssertNil(networkingSpy.sendCalls.first?.jwt, "No JWT for anonymous events")
    }

    func test_sendBatch_authConfigured_getTokenFails_reportsFailure() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { _, completion in
            completion(nil, NSError(domain: "auth", code: 401))
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [makeEvent(customer: "user-A")]

        let completionExpectation = expectation(description: "completion called")
        var groupResults: [(events: [OptistreamEvent], result: Result<Void, NetworkError>)] = []

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { groupEvents, result in
                groupResults.append((groupEvents, result))
            },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 0, "Networking should not be called on auth failure")
        XCTAssertEqual(groupResults.count, 1)
        if case .failure = groupResults.first?.result {
            // expected
        } else {
            XCTFail("Expected failure result for group")
        }
    }

    func test_sendBatch_authConfigured_mixedCustomers_splitsIntoMultipleGroups() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { userId, completion in
            completion("jwt-for-\(userId)", nil)
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [
            makeEvent(customer: "user-A", event: "e1"),
            makeEvent(customer: "user-A", event: "e2"),
            makeEvent(customer: "user-B", event: "e3"),
            makeEvent(customer: "user-B", event: "e4"),
        ]

        let completionExpectation = expectation(description: "completion called")
        var groupResults: [(events: [OptistreamEvent], result: Result<Void, NetworkError>)] = []

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { groupEvents, result in
                groupResults.append((groupEvents, result))
            },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 2, "Should send 2 separate requests")
        XCTAssertEqual(groupResults.count, 2, "onGroupResult should be called twice")

        let jwts = Set(networkingSpy.sendCalls.compactMap(\.jwt))
        XCTAssertTrue(jwts.contains("jwt-for-user-A"))
        XCTAssertTrue(jwts.contains("jwt-for-user-B"))

        let totalEvents = networkingSpy.sendCalls.reduce(0) { $0 + $1.events.count }
        XCTAssertEqual(totalEvents, 4)
    }

    func test_sendBatch_authConfigured_mixedAnonymousAndUser_splitsCorrectly() {
        let networkingSpy = OptistreamNetworkingSpy()
        var getTokenCalls: [String] = []
        let authManager = AuthManager { userId, completion in
            getTokenCalls.append(userId)
            completion("jwt-for-\(userId)", nil)
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [
            makeEvent(customer: nil, event: "anon1"),
            makeEvent(customer: nil, event: "anon2"),
            makeEvent(customer: "user-A", event: "e1"),
            makeEvent(customer: "user-A", event: "e2"),
        ]

        let completionExpectation = expectation(description: "completion called")

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { _, _ in },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(networkingSpy.sendCalls.count, 2, "Should send 2 groups")

        let anonCall = networkingSpy.sendCalls.first(where: { $0.jwt == nil })
        XCTAssertNotNil(anonCall, "Anonymous group should have nil JWT")
        XCTAssertEqual(anonCall?.events.count, 2)

        let userCall = networkingSpy.sendCalls.first(where: { $0.jwt == "jwt-for-user-A" })
        XCTAssertNotNil(userCall, "User group should have JWT")
        XCTAssertEqual(userCall?.events.count, 2)

        XCTAssertEqual(getTokenCalls, ["user-A"], "getToken should only be called for user-A, not for anonymous")
    }

    func test_sendBatch_authConfigured_multipleGroups_processesSequentially() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { userId, completion in
            completion("jwt-for-\(userId)", nil)
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [
            makeEvent(customer: "user-A"),
            makeEvent(customer: "user-B"),
            makeEvent(customer: "user-C"),
        ]

        let completionExpectation = expectation(description: "completion called")
        var groupResultOrder: [String] = []

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { groupEvents, _ in
                let customer = groupEvents.first?.customer ?? "anon"
                groupResultOrder.append(customer)
            },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(groupResultOrder.count, 3, "Should have 3 group results")
        XCTAssertEqual(networkingSpy.sendCalls.count, 3, "Should have 3 send calls")
    }

    func test_sendBatch_authConfigured_singleCustomer_callsOnGroupResultAndCompletion() {
        let networkingSpy = OptistreamNetworkingSpy()
        let authManager = AuthManager { _, completion in
            completion("jwt-123", nil)
        }
        let dispatcher = OptistreamDispatcherImpl(networking: networkingSpy, authManager: authManager)

        let events = [makeEvent(customer: "user-A"), makeEvent(customer: "user-A")]

        let completionExpectation = expectation(description: "completion called")
        let groupResultExpectation = expectation(description: "onGroupResult called")
        var receivedGroupEvents: [OptistreamEvent]?

        dispatcher.sendBatch(
            events: events,
            path: nil,
            onGroupResult: { groupEvents, result in
                receivedGroupEvents = groupEvents
                if case .success = result {
                    groupResultExpectation.fulfill()
                }
            },
            completion: {
                completionExpectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)

        XCTAssertEqual(receivedGroupEvents?.count, 2, "onGroupResult should receive the correct events")
    }
}
