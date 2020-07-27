//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
import UserNotifications
@testable import OptimoveNotificationServiceExtension

class OptimoveNotificationServiceExtensionTests: OptimoveTestCase, FileAccessible {

    var fileName: String = ""
    let networking = OptistreamNetworkingMock()
    var notificationServiceExtension: OptimoveNotificationServiceExtension!

    override func setUp() {
        notificationServiceExtension = OptimoveNotificationServiceExtension(
            bundleIdentifier: "com.apple.dt.xctest.tool",
            storage: storage,
            networking: networking
        )
    }

    func test_notification_delivery_event() throws {
        // given
        prefillStorageAsVisitor()
        fileName = "apns_payload_scheduled_campaign.json"

        let payload = try JSONDecoder().decode(
            NotificationPayload.self,
            from: data
        )

        // make content
        let content = UNMutableNotificationContent()
        content.body = payload.content
        content.title = payload.title ?? ""
        content.userInfo = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]

        // make request
        let request = UNNotificationRequest(
            identifier: "identifier",
            content: content,
            trigger: nil
        )

        //expectation from a network call
        let deliveryExpectation = expectation(description: "delivery event")
        networking.assetEventsFunction = { events, completion in
            if !events.filter({ $0.event == NotificationCampaignType.scheduled.eventName }).isEmpty {
                deliveryExpectation.fulfill()
            }
            completion(.success(()))
        }

        // when
        _ = notificationServiceExtension.didReceive(request) { (content) in
            // then
            XCTAssertNotNil(content.body)
            XCTAssertNotNil(content.title)
            XCTAssertNotNil(content.userInfo)
            XCTAssertNotNil(content.userInfo[NotificationKey.wasHandledByOptimoveNSE])
        }
        wait(for: [deliveryExpectation], timeout: 10)
    }

}
