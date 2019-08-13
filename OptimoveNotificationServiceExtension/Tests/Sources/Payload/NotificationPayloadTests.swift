// Copiright 2019 Optimove

import XCTest
@testable import OptimoveNotificationServiceExtension

class NotificationPayloadTests: XCTestCase, FileAccessible {

    var fileName: String = "Override this in a function."

    func test_decode_is_optipush_key() {
        fileName = "notificationWithCollapseKey.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.isOptipush == true)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_collapse_key() {
        fileName = "notificationWithCollapseKey.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.collapseKey != nil)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_campaign_details() {
        fileName = "notificationWithCampaignDetails.json"

        do {
            _ = try JSONDecoder().decode(NotificationPayload.self, from: data)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_deep_link_personalization_values() {
        fileName = "notificationWithDeepLinkPersonalizationValues.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.deepLinkPersonalization != nil)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_media() {
        fileName = "notificationWithMediaAttachment.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.media != nil)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

}
