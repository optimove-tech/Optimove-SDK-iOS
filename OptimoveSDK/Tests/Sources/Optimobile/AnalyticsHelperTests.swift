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
        let numberOfEventsExpectation = expectation(description: "Completion for delayed burst fired")
        let mock = mockHttpClient!
        let helper = analyticsHelper!

        helper.trackEvent(eventType: "immediate_event_first", properties: nil, immediateFlush: true)

        // A short real sleep is enough to exercise the "second burst after the first drain
        // completed" path; it doesn't need to be long, and a smaller value leaves more of the
        // longTimeoutInSeconds budget as margin against CI slowness.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            for i in 1...numberOfEvents - 1 {
                helper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }

            helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) { _ in
                // Fulfill unconditionally so a count mismatch fails fast with the actual number
                // below, instead of silently burning the full timeout with an opaque
                // "Asynchronous wait failed" error.
                numberOfEventsExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
        // +1 for immediate_event_first tracked before the delay
        XCTAssertEqual(mock.totalEventCount, numberOfEvents + 1)
    }

    func test_number_of_sent_events_from_background_threads_same_as_tracked() {
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")

        let mock = mockHttpClient!
        let helper = analyticsHelper!

        for i in 1...numberOfEvents - 1 {
            DispatchQueue.global().async {
                helper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }
        }

        helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mock.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
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
        let analyticsHelper = AnalyticsHelper(httpClient: mockKSHttpClientSingleFailure, storeUrlOverride: Self.makeTemporaryStoreUrl())
        
        let failedEventExpectation = expectation(description: "Failed event wasn't sent on next dispatch")

        analyticsHelper.trackEvent(eventType: "immeditate_event", properties: nil, immediateFlush: true)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            analyticsHelper.trackEvent(eventType: "immediate_event_second", atTime: Date(), properties: nil, immediateFlush: true) {_ in
                if let data = mockKSHttpClientSingleFailure.capturedData as? [[String: Any?]], data.count == 2 {
                    failedEventExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
}

class MockKSHttpClient: KSHttpClient {
    private var allBatches: [[String: Any?]] = []

    // Events accumulated across all sendRequest calls.
    var capturedData: Any? { allBatches.isEmpty ? nil : allBatches }
    var totalEventCount: Int { allBatches.count }

    // Last authUserId seen, and the full history.
    var capturedAuthUserId: String?
    var capturedAuthUserIds: [String?] = []

    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        if let batch = data as? [[String: Any?]] {
            allBatches.append(contentsOf: batch)
        }
        capturedAuthUserId = authUserId
        capturedAuthUserIds.append(authUserId)
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
    var capturedData: Any?
    var failed = false
    
    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        if !failed {
            onFailure(nil, NSError(domain: "domain", code: 404), nil)
            failed = true
        } else {
            capturedData = data
            onSuccess(nil, nil)
        }
    }
    
    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}
