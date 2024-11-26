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
        let numberOfEvents = 8
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        for i in 1...numberOfEvents {
            analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_number_of_sent_events_with_delays_same_as_tracked() {
        let numberOfEvents = 8
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        var totalDispatchedEvents = 0
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]] {
                totalDispatchedEvents = totalDispatchedEvents + data.count
            }
            
            if totalDispatchedEvents == numberOfEvents * 2 {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        for i in 1...numberOfEvents {
            analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            for i in 1...numberOfEvents {
                self.analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_number_of_sent_events_from_background_threads_same_as_tracked() {
        let numberOfEvents = 8
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        for i in 1...numberOfEvents {
            DispatchQueue.global().async {
                self.analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
            }
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_immediate_event_should_grab_nonimmediate() {
        let nonImmediateSentExpectation = expectation(description: "Non immediate wasn't sent with immediate")
        
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]], data.count == 2 {
                nonImmediateSentExpectation.fulfill()
            }
        }
        
        analyticsHelper.trackEvent(eventType: "immediate_event", properties: nil, immediateFlush: false)
        analyticsHelper.trackEvent(eventType: "regular_event", properties: nil, immediateFlush: true)
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
    func test_failed_network_event_shouldnt_be_picked_up_by_subsequent() {
        let mockKSHttpClientSingleFailure = MockKSHttpClientSingleFailure()
        let analyticsHelper = AnalyticsHelper(httpClient: mockKSHttpClientSingleFailure)
        
        let failedEventExpectation = expectation(description: "Failed event wasn't sent on next dispatch")
        
        var totalDispatchedEvents = 0
        
        mockKSHttpClientSingleFailure.forward = { method, data in
            if let data = data as? [[String: Any?]] {
                totalDispatchedEvents = totalDispatchedEvents + data.count
                
                if totalDispatchedEvents == 2 {
                    failedEventExpectation.fulfill()
                }
            }
        }
        
        analyticsHelper.trackEvent(eventType: "immeditate_event", properties: nil, immediateFlush: true)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            analyticsHelper.trackEvent(eventType: "delayed_immediate_event", properties: nil, immediateFlush: true)
        }
        
        waitForExpectations(timeout: longTimeoutInSeconds, handler: nil)
    }
    
}

class MockKSHttpClient: KSHttpClient {
    var forward: ((_ method: OptimoveSDK.KSHttpMethod, _ data: Any?) -> Void)?
    
    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        forward?(method, data)
        onSuccess(nil, nil)
    }
    
    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}

class MockKSHttpClientSingleFailure: KSHttpClient {
    var forward: ((_ method: OptimoveSDK.KSHttpMethod, _ data: Any?) -> Void)?
    var failed = false
    
    func sendRequest(_ method: OptimoveSDK.KSHttpMethod, toPath path: String, data: Any?, onSuccess: @escaping OptimoveSDK.KSHttpSuccessBlock, onFailure: @escaping OptimoveSDK.KSHttpFailureBlock) {
        if !failed {
            onFailure(nil, NSError(domain: "domain", code: 404), nil)
            failed = true
        } else {
            forward?(method, data)
            onSuccess(nil, nil)
        }
    }
    
    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        return
    }

}
