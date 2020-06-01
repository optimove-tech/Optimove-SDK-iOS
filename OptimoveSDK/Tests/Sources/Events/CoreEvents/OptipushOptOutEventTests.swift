//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class OptipushOptOutEventTests: XCTestCase {

    func test_event_name() {
        // given
        let timestamp = Double.pi
        let tenantBundleIdentifier = "tenantBundleIdentifier"
        let deviceId = "deviceId"

        // when
        let event = OptipushOptOutEvent(
            timestamp: timestamp,
            applicationNameSpace: tenantBundleIdentifier,
            deviceId: deviceId
        )

        // then
        XCTAssert(event.name == OptipushOptOutEvent.Constants.optOutName)
    }

    func test_event_parameters() {
        // given
        let timestamp = Double.pi
        let tenantBundleIdentifier = "tenantBundleIdentifier"
        let deviceId = "deviceId"

        // when
        let event = OptipushOptOutEvent(
            timestamp: timestamp,
            applicationNameSpace: tenantBundleIdentifier,
            deviceId: deviceId
        )

        // then
        XCTAssert(event.context[OptipushOptOutEvent.Constants.Key.timestamp] as? Int == Int(timestamp))
        XCTAssert(event.context[OptipushOptOutEvent.Constants.Key.appNs] as? String == tenantBundleIdentifier)
        XCTAssert(event.context[OptipushOptOutEvent.Constants.Key.deviceId] as? String == deviceId)
    }

}
