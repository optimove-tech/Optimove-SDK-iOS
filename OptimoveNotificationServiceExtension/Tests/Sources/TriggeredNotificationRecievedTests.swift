//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveNotificationServiceExtension

class TriggeredNotificationRecievedTests: XCTestCase {

    func test_event() {
        let actionSerial = Int.random(in: 10...1_000)
        let actionID = Int.random(in: 10...1_000)
        let templateID = Int.random(in: 10...1_000)
        let timestamp = Date().timeIntervalSince1970
        let bundleIdentifier = "BundleIdentifier"

        let event = TriggeredNotificationRecieved(
            bundleId: bundleIdentifier,
            campaign: TriggeredNotificationCampaign(
                actionSerial: actionSerial,
                actionID: actionID,
                templateID: templateID
            ),
            timestamp: timestamp
        )

        XCTAssertEqual(TriggeredNotificationRecieved.Constants.name, event.name)
        XCTAssertEqual(actionSerial, event.parameters[TriggeredNotificationRecieved.Constants.Key.actionSerial] as? Int)
        XCTAssertEqual(actionID, event.parameters[TriggeredNotificationRecieved.Constants.Key.actionID] as? Int)
        XCTAssertEqual(templateID, event.parameters[TriggeredNotificationRecieved.Constants.Key.templateID] as? Int)
        XCTAssertEqual(Int(timestamp), event.parameters[TriggeredNotificationRecieved.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(bundleIdentifier, event.parameters[TriggeredNotificationRecieved.Constants.Key.appNS] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.deviceType, event.parameters[TriggeredNotificationRecieved.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.nativeMobile, event.parameters[TriggeredNotificationRecieved.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.os, event.parameters[TriggeredNotificationRecieved.Constants.Key.eventOS] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.platform, event.parameters[TriggeredNotificationRecieved.Constants.Key.eventPlatform] as? String)
    }

}
