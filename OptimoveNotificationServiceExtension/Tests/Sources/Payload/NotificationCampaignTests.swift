//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveNotificationServiceExtension

class NotificationCampaignTests: XCTestCase, FileAccessible {

    var fileName: String = "Override this in a function."

    func test_triggered_campaing() {
        // given
        fileName = "notificationWithTriggeredCampaign.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.campaign.type == .triggered)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }

    func test_scheduled_campaing() {
        // given
        fileName = "notificationWithScheduledCampaign.json"

        do {
            let payload = try JSONDecoder().decode(NotificationPayload.self, from: data)
            XCTAssert(payload.campaign.type == .scheduled)
        } catch {
            print(error)
            XCTFail(error.localizedDescription)
        }
    }
}
