//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class SetAdvertisingIdEventTests: XCTestCase {

    func test_event_name() {
        // given
        let advertisingId = "advertisingId"
        let deviceId = "deviceId"
        let appNs = "appNs"

        // when
        let event = SetAdvertisingIdEvent(
            advertisingId: advertisingId,
            deviceId: deviceId,
            appNs: appNs
        )

        // then
        XCTAssert(event.name == SetAdvertisingIdEvent.Constants.name)
    }

    func test_event_parameters() {
        // given
        let advertisingId = "advertisingId"
        let deviceId = "deviceId"
        let appNs = "appNs"

        // when
        let event = SetAdvertisingIdEvent(
            advertisingId: advertisingId,
            deviceId: deviceId,
            appNs: appNs
        )

        // then
        XCTAssert(event.parameters[SetAdvertisingIdEvent.Constants.Key.advertisingId] as? String == advertisingId)
        XCTAssert(event.parameters[SetAdvertisingIdEvent.Constants.Key.deviceId] as? String == deviceId)
        XCTAssert(event.parameters[SetAdvertisingIdEvent.Constants.Key.appNS] as? String == appNs)
    }

}
