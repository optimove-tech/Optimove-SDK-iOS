//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

class NotificationCampaignTests: XCTestCase, FileAccessible {

    var fileName: String = "Override this in a function."

    func test_triggered_campaing() {
        // given
        fileName = "notificationWithTriggeredCampaign.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssertEqual(payload.campaign?.type, .triggered)
        }
    }

    func test_scheduled_campaing() {
        // given
        fileName = "notificationWithScheduledCampaign.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssertEqual(payload.campaign?.type, .scheduled)
        }
    }

    func test_no_campaign() {
        // given
        fileName = "test_notification.json"

        tryDecode {
           let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
           XCTAssertNil(payload.campaign)
        }
    }
}
