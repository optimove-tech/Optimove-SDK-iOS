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
        let numberOfEvents = 10;
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        for i in 1...numberOfEvents {
            self.analyticsHelper.trackEvent(eventType: "immediate_event\(i)", properties: nil, immediateFlush: true)
        }
        
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }
    
    
    func test_immediate_event_should_grab_nonimmediate() {
        let numberOfEvents = 2;
        let numberOfEventsExpectation = expectation(description: "Number of events wasnt \(numberOfEvents)")
        
        mockHttpClient.forward = { method, data in
            if let data = data as? [[String: Any?]], data.count == numberOfEvents {
                numberOfEventsExpectation.fulfill()
            }
        }
        
        self.analyticsHelper.trackEvent(eventType: "immediate_event", properties: nil, immediateFlush: false)
        self.analyticsHelper.trackEvent(eventType: "regular_event", properties: nil, immediateFlush: true)
        
        waitForExpectations(timeout: defaultTimeout, handler: nil)
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
