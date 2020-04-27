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
                templateID: templateID,
                engagementID: 1_234
            ),
            timestamp: Int(timestamp)
        )

        XCTAssertEqual(TriggeredNotificationRecieved.Constants.name, event.name)
        XCTAssertEqual(actionSerial, event.context[TriggeredNotificationRecieved.Constants.Key.actionSerial] as? Int)
        XCTAssertEqual(actionID, event.context[TriggeredNotificationRecieved.Constants.Key.actionID] as? Int)
        XCTAssertEqual(templateID, event.context[TriggeredNotificationRecieved.Constants.Key.templateID] as? Int)
        XCTAssertEqual(Int(timestamp), event.context[TriggeredNotificationRecieved.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(bundleIdentifier, event.context[TriggeredNotificationRecieved.Constants.Key.appNS] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.deviceType, event.context[TriggeredNotificationRecieved.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.nativeMobile, event.context[TriggeredNotificationRecieved.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.os, event.context[TriggeredNotificationRecieved.Constants.Key.eventOS] as? String)
        XCTAssertEqual(TriggeredNotificationRecieved.Constants.Value.platform, event.context[TriggeredNotificationRecieved.Constants.Key.eventPlatform] as? String)
    }

}
