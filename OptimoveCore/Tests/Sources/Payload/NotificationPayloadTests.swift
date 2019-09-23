//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

class NotificationPayloadTests: XCTestCase, FileAccessible {

    var fileName: String = "Override this in a function."

    func test_decode_is_optipush_key() {
        fileName = "notificationWithCollapseKey.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.isOptipush == true)
        }
    }

    func test_decode_collapse_key() {
        fileName = "notificationWithCollapseKey.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.collapseKey != nil)
        }
    }

    func test_decode_campaign_details() {
        fileName = "notificationWithCampaignDetails.json"

        tryDecode {
            _ = try JSONDecoder().decode(NotificationPayload.self, from: data)
        }
    }

    func test_decode_deep_link_personalization_values() {
        fileName = "notificationWithDeepLinkPersonalizationValues.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.deepLinkPersonalization != nil)
        }
    }

    func test_decode_media() {
        fileName = "notificationWithMediaAttachment.json"

        tryDecode {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.media != nil)
        }
    }

}
