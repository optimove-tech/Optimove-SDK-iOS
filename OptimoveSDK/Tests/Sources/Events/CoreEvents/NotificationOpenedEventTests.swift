//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class NotificationOpenedEventTests: XCTestCase {

    func test_scheduled_opened_event() {
        let campaign = NotificationCampaignType.scheduled
        let identityToken = "identity_token"
        let bundleIdentifier = StubVariables.string
        let timestamp = Date()

        // when
        let event = NotificationOpenedEvent(
            bundleIdentifier: bundleIdentifier,
            notificationType: campaign,
            identityToken: identityToken,
            requestId: "request_id",
            timestamp: timestamp
        )

        // then
        XCTAssertEqual(event.name, campaign.eventName)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.appNS] as? String, bundleIdentifier)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.identityToken] as? String, identityToken)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.timestamp] as? Int64, timestamp.timeIntervalSince1970.seconds)
    }

    func test_triggered_opened_event() {
        let campaign = NotificationCampaignType.triggered
        let identityToken = "identity_token"
        let bundleIdentifier = StubVariables.string
        let timestamp = Date()

        // when
        let event = NotificationOpenedEvent(
            bundleIdentifier: bundleIdentifier,
            notificationType: campaign,
            identityToken: identityToken,
            requestId: "request_id",
            timestamp: timestamp
        )

        // then
        XCTAssertEqual(event.name, campaign.eventName)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.appNS] as? String, bundleIdentifier)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.identityToken] as? String, identityToken)
        XCTAssertEqual(event.context[NotificationOpenedEvent.Constants.Key.timestamp] as? Int64, timestamp.timeIntervalSince1970.seconds)
    }

}
