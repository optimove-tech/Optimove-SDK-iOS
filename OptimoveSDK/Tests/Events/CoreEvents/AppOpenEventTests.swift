// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

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
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.bundleIdentifier] as? String == bundleIdentifier)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.visitorId] as? String == visitorID)
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
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.bundleIdentifier] as? String == bundleIdentifier)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.customerId] as? String == customerID)
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
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.bundleIdentifier] as? String == bundleIdentifier)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.customerId] as? String == customerID)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.visitorId] == nil)
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
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.bundleIdentifier] as? String == bundleIdentifier)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.deviceID] as? String == deviceID)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.customerId] == nil)
        XCTAssert(event.parameters[AppOpenEvent.Constants.Key.visitorId] as? String == visitorID)
    }

}
