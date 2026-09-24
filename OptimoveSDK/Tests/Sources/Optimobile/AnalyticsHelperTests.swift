//
//  Test.swift
//  Optimove
//
//  Created by Kostya Antipochkin on 2024-11-22.
//

import XCTest
@testable import OptimoveSDK
import OptimoveTest

class AnalyticsHelperTests: XCTestCase {
    
    var mockHttpClient: MockKSHttpClient!
    var analyticsHelper: AnalyticsHelper!
    var longTimeoutInSeconds = 10.0
    private var storeUrl: URL!
    
    override func setUp() {
        super.setUp()
        storeUrl = Self.makeTemporaryStoreUrl()
        mockHttpClient = MockKSHttpClient()
        analyticsHelper = AnalyticsHelper(httpClient: mockHttpClient, storeUrlOverride: storeUrl)
    }

    /// A fresh, uniquely-named store per test/instance, in a scratch directory.
    ///
    /// Deliberately does not rely on `AnalyticsHelper`'s own Documents/shared-container
    /// path resolution: on the simulator, `containerURL(forSecurityApplicationGroupIdentifier:)`
    /// resolves successfully for arbitrary group identifiers (entitlements aren't enforced
    /// there), so `AnalyticsHelper` silently opens the shared-container database instead of
    /// the Documents one — a previous version of this helper cleared the Documents database,
    /// which was never the one actually in use, so tests never had real isolation.
    static func makeTemporaryStoreUrl() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnalyticsHelperTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("KAnalyticsDb.sqlite")
    }

    static func removeStore(at url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            let fileUrl = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + suffix)
            try? FileManager.default.removeItem(at: fileUrl)
        }
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
    
    override func tearDown()
    {
        analyticsHelper = nil
        mockHttpClient = nil
        Self.removeStore(at: storeUrl)
        storeUrl = nil
        super.tearDown()
    }
    
    // Closures below capture `mockHttpClient` / `analyticsHelper` as local strong refs
    // so a late callback firing after tearDown can't crash on `self.mockHttpClient!`.

    func test_number_of_sent_events_same_as_tracked() {
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        let mock = mockHttpClient!

        for i in 1...numberOfEvents - 1 {
            analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }

        self.analyticsHelper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mock.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }

    func test_number_of_sent_events_with_delays_same_as_tracked() {
        let numberOfEvents = 4
        let firstBurstDelivered = expectation(description: "The first event was delivered")
        let secondBurstDelivered = expectation(description: "The second burst was delivered")
        let mock = mockHttpClient!
        let helper = analyticsHelper!

        // What this test is about is the second burst starting *after* the first drain finished.
        // Waiting for the first delivery says so directly; sleeping and hoping the drain fit in
        // the nap makes it a race, and a loaded machine is exactly where the nap is too short.
        helper.trackEvent(eventType: "immediate_event_first", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            firstBurstDelivered.fulfill()
        }
        wait(for: [firstBurstDelivered], timeout: longTimeoutInSeconds)

        for i in 1...numberOfEvents - 1 {
            helper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }

        helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            secondBurstDelivered.fulfill()
        }
        // The helper drains on one serial queue, so by the time the last event's send has completed
        // the earlier ones in the burst have too.
        wait(for: [secondBurstDelivered], timeout: longTimeoutInSeconds)

        // +1 for immediate_event_first, delivered before the burst
        XCTAssertEqual(mock.totalEventCount, numberOfEvents + 1)
    }

    func test_number_of_sent_events_from_background_threads_same_as_tracked() {
        let numberOfEvents = 4
        let backgroundEventsDelivered = expectation(description: "The events tracked from background queues were delivered")
        backgroundEventsDelivered.expectedFulfillmentCount = numberOfEvents - 1
        let lastEventDelivered = expectation(description: "The last event was delivered")

        let mock = mockHttpClient!
        let helper = analyticsHelper!

        for i in 1...numberOfEvents - 1 {
            DispatchQueue.global().async {
                helper.trackEvent(eventType: "immediate_event\(i)", atTime: Date(), properties: nil, immediateFlush: true) { _ in
                    backgroundEventsDelivered.fulfill()
                }
            }
        }

        // Still tracked concurrently from several queues, which is the point — but the count is
        // only checked once those deliveries are known to have happened. Tracking the last event
        // straight away instead left the assertion racing the background queues, and the loser
        // was whichever the scheduler felt like.
        wait(for: [backgroundEventsDelivered], timeout: longTimeoutInSeconds)

        helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            lastEventDelivered.fulfill()
        }
        wait(for: [lastEventDelivered], timeout: longTimeoutInSeconds)

        XCTAssertEqual(mock.totalEventCount, numberOfEvents)
    }

    func test_immediate_event_should_grab_nonimmediate() {
        let nonImmediateSentExpectation = expectation(description: "Non immediate wasn't sent with immediate")

        let mock = mockHttpClient!

        analyticsHelper.trackEvent(eventType: "regular_event", properties: nil, immediateFlush: false)
        analyticsHelper.trackEvent(eventType: "immediate_event", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mock.capturedData as? [[String: Any?]], data.count == 2 {
                nonImmediateSentExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_failed_network_event_should_be_picked_up_by_subsequent() {
        let mockKSHttpClientSingleFailure = MockKSHttpClientSingleFailure()
        let storeUrl = Self.makeTemporaryStoreUrl()
        let analyticsHelper = AnalyticsHelper(httpClient: mockKSHttpClientSingleFailure, storeUrlOverride: storeUrl)
        defer { Self.removeStore(at: storeUrl) }

        // The second event has to be tracked after the first send has actually failed, otherwise
        // there is nothing for it to pick up. The mock says when that happened instead of the test
        // sleeping for two seconds and assuming it did.
        let firstSendFailed = expectation(description: "The first send was answered with a failure")
        mockKSHttpClientSingleFailure.onFailureDelivered = { firstSendFailed.fulfill() }

        analyticsHelper.trackEvent(eventType: "immeditate_event", properties: nil, immediateFlush: true)
        wait(for: [firstSendFailed], timeout: longTimeoutInSeconds)

        let secondSendDelivered = expectation(description: "The second send completed")
        analyticsHelper.trackEvent(eventType: "immediate_event_second", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            secondSendDelivered.fulfill()
        }
        wait(for: [secondSendDelivered], timeout: longTimeoutInSeconds)

        let batch = mockKSHttpClientSingleFailure.capturedData as? [[String: Any?]]
        XCTAssertEqual(batch?.count, 2, "The event whose send failed should be retried alongside the next one")
    }
    
}

/// `sendRequest` is called from the helper's serial queue while the tests read these properties
/// from the test thread, so the state is behind a lock. Without it the tests race the mock itself,
/// and a torn read of an array is a corrupt count, not a caught bug.
class MockKSHttpClient: KSHttpClient {
    private let lock = NSLock()
    private var allBatches: [[String: Any?]] = []
    private var authUserIds: [String?] = []

    // Events accumulated across all sendRequest calls.
    var capturedData: Any? { withLock { allBatches.isEmpty ? nil : allBatches } }
    var totalEventCount: Int { withLock { allBatches.count } }

    // Last authUserId seen, and the full history.
    var capturedAuthUserId: String? { withLock { authUserIds.last ?? nil } }
    var capturedAuthUserIds: [String?] { withLock { authUserIds } }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        withLock {
            if let batch = data as? [[String: Any?]] {
                allBatches.append(contentsOf: batch)
            }
            authUserIds.append(authUserId)
        }
        onSuccess(nil, nil)
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}

// MARK: - Auth-specific Tests

class AnalyticsHelperAuthTests: XCTestCase {

    var mockHttpClient: MockKSHttpClient!
    var analyticsHelper: AnalyticsHelper!
    var longTimeoutInSeconds = 10.0
    private var storeUrl: URL!

    override func setUp() {
        super.setUp()
        // Isolate from prior runs: stale events / leftover USER_ID can corrupt expectations.
        storeUrl = AnalyticsHelperTests.makeTemporaryStoreUrl()
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)
        mockHttpClient = MockKSHttpClient()
        analyticsHelper = AnalyticsHelper(httpClient: mockHttpClient, storeUrlOverride: storeUrl)
    }

    override func tearDown() {
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)
        analyticsHelper = nil
        mockHttpClient = nil
        AnalyticsHelperTests.removeStore(at: storeUrl)
        storeUrl = nil
        super.tearDown()
    }

    // No user associated → currentUserIdentifier == installId → syncEventsBatch passes authUserId: nil.
    func test_syncEventsBatch_defaultVisitorEvents_passesNilAuthUserId() {
        let authUserIdExpectation = expectation(description: "authUserId should be nil for visitor events")
        let mock = mockHttpClient!

        analyticsHelper.trackEvent(eventType: "visitor_event", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            if mock.capturedAuthUserId == nil {
                authUserIdExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }

    // User associated → events stamped with that id → syncEventsBatch passes authUserId: <userId>.
    func test_syncEventsBatch_associatedUser_passesAuthUserId() {
        let testUserId = "user-123"
        KeyValPersistenceHelper.set(testUserId, forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)

        let authUserIdExpectation = expectation(description: "authUserId should be the user's identifier")
        let mock = mockHttpClient!

        analyticsHelper.trackEvent(eventType: "user_event", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            if mock.capturedAuthUserId == testUserId {
                authUserIdExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
}

class MockKSHttpClientSingleFailure: KSHttpClient {
    private let lock = NSLock()
    private var lastSuccessfulBatch: Any?
    private var failed = false

    var capturedData: Any? { withLock { lastSuccessfulBatch } }

    /// Fires once the first request has been answered with a failure, so a test can sequence the
    /// next request after it rather than sleeping for long enough and hoping.
    var onFailureDelivered: (() -> Void)?

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        let isFirstRequest = withLock { () -> Bool in
            guard !failed else { return false }
            failed = true
            return true
        }

        if isFirstRequest {
            onFailure(nil, NSError(domain: "domain", code: 404), nil)
            // After the helper has handled the failure, so a test resuming here sees the event
            // already back in the store.
            onFailureDelivered?()
            return
        }

        withLock { lastSuccessfulBatch = data }
        onSuccess(nil, nil)
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}
