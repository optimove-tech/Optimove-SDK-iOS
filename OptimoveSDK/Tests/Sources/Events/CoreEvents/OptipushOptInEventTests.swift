// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class OptipushOptInEventTests: XCTestCase {

    func test_event_name() {
        // given
        let timestamp = Double.pi
        let tenantBundleIdentifier = "tenantBundleIdentifier"
        let deviceId = "deviceId"

        // when
        let event = OptipushOptInEvent(
            timestamp: timestamp,
            applicationNameSpace: tenantBundleIdentifier,
            deviceId: deviceId
        )

        // then
        XCTAssert(event.name == OptipushOptInEvent.Constants.optInName)
    }

    func test_event_parameters() {
        // given
        let timestamp = Double.pi
        let tenantBundleIdentifier = "tenantBundleIdentifier"
        let deviceId = "deviceId"

        // when
        let event = OptipushOptInEvent(
            timestamp: timestamp,
            applicationNameSpace: tenantBundleIdentifier,
            deviceId: deviceId
        )

        // then
        XCTAssert(event.parameters[OptipushOptInEvent.Constants.Key.timestamp] as? Int == Int(timestamp))
        XCTAssert(event.parameters[OptipushOptInEvent.Constants.Key.appNs] as? String == tenantBundleIdentifier)
        XCTAssert(event.parameters[OptipushOptInEvent.Constants.Key.deviceId] as? String == deviceId)
    }

}
