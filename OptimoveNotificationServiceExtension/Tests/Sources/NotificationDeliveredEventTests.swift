//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveNotificationServiceExtension

class NotificationDeliveredEventTests: XCTestCase {

    func test_scheduled_event() {
        let identityToken = "identity_token"
        let bundleIdentifier = "BundleIdentifier"
        let notificationType = NotificationCampaignType.scheduled
        let timestamp = Date()

        let event = NotificationDeliveredEvent(
            bundleId: bundleIdentifier,
            notificationType: notificationType,
            identityToken: identityToken,
            timestamp: timestamp
        )

        XCTAssertEqual(notificationType.eventName, event.name)
        XCTAssertEqual(timestamp.timeIntervalSince1970.seconds, event.context[NotificationDeliveredEvent.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(identityToken, event.context[NotificationDeliveredEvent.Constants.Key.identityToken] as? String)
        XCTAssertEqual(bundleIdentifier, event.context[NotificationDeliveredEvent.Constants.Key.appNS] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.deviceType, event.context[NotificationDeliveredEvent.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.nativeMobile, event.context[NotificationDeliveredEvent.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.os, event.context[NotificationDeliveredEvent.Constants.Key.eventOS] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.platform, event.context[NotificationDeliveredEvent.Constants.Key.eventPlatform] as? String)
    }

    func test_triggered_event() {
        let identityToken = "identity_token"
        let bundleIdentifier = "BundleIdentifier"
        let notificationType = NotificationCampaignType.triggered
        let timestamp = Date()

        let event = NotificationDeliveredEvent(
            bundleId: bundleIdentifier,
            notificationType: notificationType,
            identityToken: identityToken,
            timestamp: timestamp
        )

        XCTAssertEqual(notificationType.eventName, event.name)
        XCTAssertEqual(timestamp.timeIntervalSince1970.seconds, event.context[NotificationDeliveredEvent.Constants.Key.timestamp] as? Int)
        XCTAssertEqual(identityToken, event.context[NotificationDeliveredEvent.Constants.Key.identityToken] as? String)
        XCTAssertEqual(bundleIdentifier, event.context[NotificationDeliveredEvent.Constants.Key.appNS] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.deviceType, event.context[NotificationDeliveredEvent.Constants.Key.eventDeviceType] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.nativeMobile, event.context[NotificationDeliveredEvent.Constants.Key.eventNativeMobile] as? Bool)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.os, event.context[NotificationDeliveredEvent.Constants.Key.eventOS] as? String)
        XCTAssertEqual(NotificationDeliveredEvent.Constants.Value.platform, event.context[NotificationDeliveredEvent.Constants.Key.eventPlatform] as? String)
    }
}
