//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

class AppOpenEventTests: XCTestCase {
    func test_event_name() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let deviceID = "deviceID"
        let visitorID = "visitorId"
        let customerID = "customerID"

        // when
        let event = AppOpenEvent(
            bundleIdentifier: bundleIdentifier,
            deviceID: deviceID,
            visitorID: visitorID,
            customerID: customerID
        )

        // then
        XCTAssert(event.name == AppOpenEvent.Constants.name)
    }

    func test_event_parameters_visitor() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let deviceID = "deviceID"
        let visitorID = "visitorId"

        // when
        let event = AppOpenEvent(
            bundleIdentifier: bundleIdentifier,
            deviceID: deviceID,
            visitorID: visitorID,
            customerID: nil
        )

        // then
        XCTAssert(event.context[AppOpenEvent.Constants.Key.appNS] as? String == bundleIdentifier)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.visitorID] as? String == visitorID)
    }

    func test_event_parameters_customer() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let deviceID = "deviceID"
        let customerID = "customerID"

        // when
        let event = AppOpenEvent(
            bundleIdentifier: bundleIdentifier,
            deviceID: deviceID,
            visitorID: nil,
            customerID: customerID
        )

        // then
        XCTAssert(event.context[AppOpenEvent.Constants.Key.appNS] as? String == bundleIdentifier)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.userID] as? String == customerID)
    }

    func test_event_if_customer_no_visitor() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let deviceID = "deviceID"
        let visitorID = "visitorId"
        let customerID = "customerID"

        // when
        let event = AppOpenEvent(
            bundleIdentifier: bundleIdentifier,
            deviceID: deviceID,
            visitorID: visitorID,
            customerID: customerID
        )

        // then
        XCTAssert(event.context[AppOpenEvent.Constants.Key.appNS] as? String == bundleIdentifier)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.userID] as? String == customerID)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.visitorID] == nil)
    }

    func test_event_if_visitor_no_cutomer() {
        // given
        let bundleIdentifier = "bundleIdentifier"
        let deviceID = "deviceID"
        let visitorID = "visitorId"

        // when
        let event = AppOpenEvent(
            bundleIdentifier: bundleIdentifier,
            deviceID: deviceID,
            visitorID: visitorID,
            customerID: nil
        )

        // then
        XCTAssert(event.context[AppOpenEvent.Constants.Key.appNS] as? String == bundleIdentifier)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.userID] == nil)
        XCTAssert(event.context[AppOpenEvent.Constants.Key.visitorID] as? String == visitorID)
    }
}
