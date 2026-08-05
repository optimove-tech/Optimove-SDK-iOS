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

    override func setUp() {
        super.setUp()
        clearAnalyticsStore()
        mockHttpClient = MockKSHttpClient()
        analyticsHelper = AnalyticsHelper(httpClient: mockHttpClient)
    }

    private func clearAnalyticsStore() {
        guard let docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else { return }
        let dbUrl = docsUrl.appendingPathComponent("KAnalyticsDb.sqlite")
        for suffix in ["", "-shm", "-wal"] {
            let url = dbUrl.deletingLastPathComponent().appendingPathComponent(dbUrl.lastPathComponent + suffix)
            try? FileManager.default.removeItem(at: url)
        }
    }

    override func tearDown()
    {
        analyticsHelper = nil
        mockHttpClient = nil
        super.tearDown()
    }

    // A flush completion can outlive waitForExpectations, and tearDown then sets
    // mockHttpClient and analyticsHelper to nil. Reading them through self from
    // inside a completion crashes the whole test binary on the implicit unwrap,
    // which shows up as an unrelated test failing later in the run. Capture what
    // the completion needs before tracking, so it holds its own strong reference.

    func test_number_of_sent_events_same_as_tracked() {
        let helper = analyticsHelper!
        let mock = mockHttpClient!
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")

        for i in 1...numberOfEvents - 1 {
            helper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }

        helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mock.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }

        wait(for: [numberOfEventsExpectation], timeout: longTimeoutInSeconds)
    }

    func test_number_of_sent_events_with_delays_same_as_tracked() {
        let helper = analyticsHelper!
        let mock = mockHttpClient!
        let numberOfEvents = 4

        // The point of this test is that events tracked in a later, separate flush
        // are still all delivered. Waiting for the first flush to report completion
        // establishes that separation directly. A sleep only made it likely, and
        // spent 2 of the 10 second budget doing nothing, which is what tipped this
        // test into timing out on a loaded CI runner.
        let firstEventFlushed = expectation(description: "First event was flushed")
        helper.trackEvent(eventType: "immediate_event_first", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            firstEventFlushed.fulfill()
        }
        wait(for: [firstEventFlushed], timeout: longTimeoutInSeconds)

        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents + 1)")

        for i in 1...numberOfEvents - 1 {
            helper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }

        helper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            // +1 for immediate_event_first tracked before the first flush
            if mock.totalEventCount == numberOfEvents + 1 {
                numberOfEventsExpectation.fulfill()
            }
        }

        wait(for: [numberOfEventsExpectation], timeout: longTimeoutInSeconds)
    }

    func test_number_of_sent_events_from_background_threads_same_as_tracked() {
        let helper = analyticsHelper!
        let mock = mockHttpClient!
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")

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

        wait(for: [numberOfEventsExpectation], timeout: longTimeoutInSeconds)
    }

    func test_immediate_event_should_grab_nonimmediate() {
        let helper = analyticsHelper!
        let mock = mockHttpClient!
        let nonImmediateSentExpectation = expectation(description: "Non immediate wasn't sent with immediate")

        helper.trackEvent(eventType: "regular_event", properties: nil, immediateFlush: false)
        helper.trackEvent(eventType: "immediate_event", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mock.capturedData as? [[String: Any?]], data.count == 2 {
                nonImmediateSentExpectation.fulfill()
            }
        }

        wait(for: [nonImmediateSentExpectation], timeout: longTimeoutInSeconds)
    }

    func test_failed_network_event_should_be_picked_up_by_subsequent() {
        let mockKSHttpClientSingleFailure = MockKSHttpClientSingleFailure()
        let analyticsHelper = AnalyticsHelper(httpClient: mockKSHttpClientSingleFailure)

        // Wait for the send to actually fail instead of sleeping and assuming it
        // has, so the second event is guaranteed to be the subsequent dispatch.
        let firstSendFailed = expectation(description: "First send wasn't failed")
        mockKSHttpClientSingleFailure.onFailureDelivered = { firstSendFailed.fulfill() }

        analyticsHelper.trackEvent(eventType: "immeditate_event", properties: nil, immediateFlush: true)
        wait(for: [firstSendFailed], timeout: longTimeoutInSeconds)

        let failedEventExpectation = expectation(description: "Failed event wasn't sent on next dispatch")

        analyticsHelper.trackEvent(eventType: "immediate_event_second", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = mockKSHttpClientSingleFailure.capturedData as? [[String: Any?]], data.count == 2 {
                failedEventExpectation.fulfill()
            }
        }

        wait(for: [failedEventExpectation], timeout: longTimeoutInSeconds)
    }

}

class MockKSHttpClient: KSHttpClient {
    // Written on whichever queue AnalyticsHelper flushes from and read from test
    // completions, so every access is behind the lock.
    private let lock = NSLock()
    private var allBatches: [[String: Any?]] = []

    // Last batch sent (used by tests that check a single-batch payload)
    var capturedData: Any? {
        lock.lock()
        defer { lock.unlock() }
        return allBatches.isEmpty ? nil : allBatches
    }

    // Total events accumulated across all requests
    var totalEventCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return allBatches.count
    }

    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        if let batch = data as? [[String: Any?]] {
            lock.lock()
            allBatches.append(contentsOf: batch)
            lock.unlock()
        }
        onSuccess(nil, nil)
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}

class MockKSHttpClientSingleFailure: KSHttpClient {
    private let lock = NSLock()
    private var _capturedData: Any?
    private var failed = false

    // Called once the first, deliberately failed, send has been reported back.
    var onFailureDelivered: (() -> Void)?

    var capturedData: Any? {
        lock.lock()
        defer { lock.unlock() }
        return _capturedData
    }

    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        lock.lock()
        let alreadyFailed = failed
        if !alreadyFailed {
            failed = true
        } else {
            _capturedData = data
        }
        lock.unlock()

        if !alreadyFailed {
            onFailure(nil, NSError(domain: "domain", code: 404), nil)
            onFailureDelivered?()
        } else {
            onSuccess(nil, nil)
        }
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}
