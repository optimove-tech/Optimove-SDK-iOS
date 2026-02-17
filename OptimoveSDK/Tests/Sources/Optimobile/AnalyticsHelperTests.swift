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
        mockHttpClient = MockKSHttpClient()
        analyticsHelper = AnalyticsHelper(httpClient: mockHttpClient)
    }
    
    override func tearDown()
    {
        analyticsHelper = nil
        mockHttpClient = nil
        super.tearDown()
    }
    
    func test_number_of_sent_events_same_as_tracked() {
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        for i in 1...numberOfEvents - 1 {
            analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }
        
        self.analyticsHelper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = self.mockHttpClient.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_number_of_sent_events_with_delays_same_as_tracked() {
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        analyticsHelper.trackEvent(eventType: "immediate_event_first", properties: nil, immediateFlush: true)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            for i in 1...numberOfEvents - 1 {
                self.analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }
            
            self.analyticsHelper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
                if let data = self.mockHttpClient.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                    numberOfEventsExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_number_of_sent_events_from_background_threads_same_as_tracked() {
        let numberOfEvents = 4
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
    
        
        for i in 1...numberOfEvents - 1 {
            DispatchQueue.global().async {
                self.analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }
        }
        
        analyticsHelper.trackEvent(eventType: "immediate_event_last", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = self.mockHttpClient.capturedData as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_immediate_event_should_grab_nonimmediate() {
        let nonImmediateSentExpectation = expectation(description: "Non immediate wasn't sent with immediate")
    
        
        analyticsHelper.trackEvent(eventType: "regular_event", properties: nil, immediateFlush: false)
        analyticsHelper.trackEvent(eventType: "immediate_event", atTime: Date(), properties: nil, immediateFlush: true) {_ in
            if let data = self.mockHttpClient.capturedData as? [[String: Any?]], data.count == 2 {
                nonImmediateSentExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_failed_network_event_should_be_picked_up_by_subsequent() {
        let mockKSHttpClientSingleFailure = MockKSHttpClientSingleFailure()
        let analyticsHelper = AnalyticsHelper(httpClient: mockKSHttpClientSingleFailure)
        
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
    var capturedData: Any?
    var capturedAuthUserId: String?
    var capturedAuthUserIds: [String?] = []
    
    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        capturedData = data
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

    override func setUp() {
        super.setUp()
        mockHttpClient = MockKSHttpClient()
        analyticsHelper = AnalyticsHelper(httpClient: mockHttpClient)
    }

    override func tearDown() {
        analyticsHelper = nil
        mockHttpClient = nil
        super.tearDown()
    }

    // By default, without calling associateUserWithInstall, currentUserIdentifier == installId.
    // The syncEventsBatch code detects this as a visitor batch and passes authUserId: nil.

    func test_syncEventsBatch_defaultVisitorEvents_passesNilAuthUserId() {
        let authUserIdExpectation = expectation(description: "authUserId should be nil for visitor events")

        analyticsHelper.trackEvent(eventType: "visitor_event", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            if self.mockHttpClient.capturedAuthUserId == nil {
                authUserIdExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }

    // After associateUserWithInstall, currentUserIdentifier returns the user's ID.
    // Events stamped with that ID should be sent with authUserId set.

    func test_syncEventsBatch_associatedUser_passesAuthUserId() {
        let testUserId = "user-123"

        // Associate a user. This changes OptimobileHelper.currentUserIdentifier.
        KeyValPersistenceHelper.set(testUserId, forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)

        let authUserIdExpectation = expectation(description: "authUserId should be the user's identifier")

        analyticsHelper.trackEvent(eventType: "user_event", atTime: Date(), properties: nil, immediateFlush: true) { _ in
            if self.mockHttpClient.capturedAuthUserId == testUserId {
                authUserIdExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)

        // Cleanup: restore to visitor
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)
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
