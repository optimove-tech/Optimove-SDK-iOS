//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveNotificationServiceExtension

class ScheduledNotificationDeliveredTests: XCTestCase {

    func testExample() {
        let campaignID = Int.random(in: 10...1_000)
        let actionSerial = Int.random(in: 10...1_000)
        let templateID = Int.random(in: 10...1_000)
        let engagementID = Int.random(in: 10...1_000)
        let campaignType = Int.random(in: 1...2)
        let timestamp = Date().timeIntervalSince1970
        let bundleIdentifier = "BundleIdentifier"

        let event = ScheduledNotificationDelivered(
            bundleId: bundleIdentifier,
            campaign: ScheduledNotificationCampaign(
                campaignID: campaignID,
                actionSerial: actionSerial,
                templateID: templateID,
                engagementID: engagementID,
                campaignType: campaignType
            ),
            timestamp: Int(timestamp)
        )

        XCTAssertEqual(ScheduledNotificationDelivered.Constants.name, event.name)
        XCTAssertEqual(actionSerial, event.context[ScheduledNotificationDelivered.Constants.Key.actionSerial] as? Int)
        XCTAssertEqual(campaignID, event.context[ScheduledNotificationDelivered.Constants.Key.campaignID] as? Int)
        XCTAssertEqual(engagementID, event.context[ScheduledNotificationDelivered.Constants.Key.engagementID] as? Int)
        XCTAssertEqual(campaignType, event.context[ScheduledNotificationDelivered.Constants.Key.campaignType] as? Int)
        XCTAssertEqual(templateID, event.context[ScheduledNotificationDelivered.Constants.Key.templateID] as? Int)
        XCTAssertEqual(Int(timestamp), event.context[ScheduledNotificationDelivered.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(bundleIdentifier, event.context[ScheduledNotificationDelivered.Constants.Key.appNS] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.deviceType, event.context[ScheduledNotificationDelivered.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.nativeMobile, event.context[ScheduledNotificationDelivered.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.os, event.context[ScheduledNotificationDelivered.Constants.Key.eventOS] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.platform, event.context[ScheduledNotificationDelivered.Constants.Key.eventPlatform] as? String)
    }
}
