// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class PingEventTests: XCTestCase {

    func test_event_name() {
        // given
        let visitorId = "visitorId"
        let deviceId = "deviceId"
        let appNs = "appNs"

        // when
        let event = PingEvent(visitorId: visitorId, deviceId: deviceId, appNs: appNs)

        // then
        XCTAssert(event.name == PingEvent.Constants.name)
    }

    func test_event_parameters() {
        // given
        let visitorId = "visitorId"
        let deviceId = "deviceId"
        let appNs = "appNs"

        // when
        let event = PingEvent(visitorId: visitorId, deviceId: deviceId, appNs: appNs)

        // then
        XCTAssert(event.parameters[PingEvent.Constants.Key.visitorId] as? String == visitorId)
        XCTAssert(event.parameters[PingEvent.Constants.Key.deviceId] as? String == deviceId)
        XCTAssert(event.parameters[PingEvent.Constants.Key.appNs] as? String == appNs)
    }
}
