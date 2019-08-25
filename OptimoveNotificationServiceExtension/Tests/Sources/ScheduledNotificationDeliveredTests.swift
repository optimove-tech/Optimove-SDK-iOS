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
            timestamp:  timestamp
        )

        XCTAssertEqual(ScheduledNotificationDelivered.Constants.name, event.name)
        XCTAssertEqual(actionSerial, event.parameters[ScheduledNotificationDelivered.Constants.Key.actionSerial] as? Int)
        XCTAssertEqual(campaignID, event.parameters[ScheduledNotificationDelivered.Constants.Key.campaignID] as? Int)
        XCTAssertEqual(engagementID, event.parameters[ScheduledNotificationDelivered.Constants.Key.engagementID] as? Int)
        XCTAssertEqual(campaignType, event.parameters[ScheduledNotificationDelivered.Constants.Key.campaignType] as? Int)
        XCTAssertEqual(templateID, event.parameters[ScheduledNotificationDelivered.Constants.Key.templateID] as? Int)
        XCTAssertEqual(Int(timestamp), event.parameters[ScheduledNotificationDelivered.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(bundleIdentifier, event.parameters[ScheduledNotificationDelivered.Constants.Key.appNS] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.deviceType, event.parameters[ScheduledNotificationDelivered.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.nativeMobile, event.parameters[ScheduledNotificationDelivered.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.os, event.parameters[ScheduledNotificationDelivered.Constants.Key.eventOS] as? String)
        XCTAssertEqual(ScheduledNotificationDelivered.Constants.Value.platform, event.parameters[ScheduledNotificationDelivered.Constants.Key.eventPlatform] as? String)
    }
}
