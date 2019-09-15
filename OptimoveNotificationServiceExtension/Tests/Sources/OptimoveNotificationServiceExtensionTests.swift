//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
import UserNotifications
@testable import OptimoveNotificationServiceExtension

class OptimoveNotificationServiceExtensionTests: XCTestCase, FileAccessible {

    var fileName: String = "notificationWithScheduledCampaign.json"
    var storage = MockOptimoveStorage()
    let mock = MockOptitrackNSE()
    var notificationService: OptimoveNotificationServiceExtension!

    override func setUp() {
        notificationService = OptimoveNotificationServiceExtension(appBundleId: "com.apple.dt.xctest.tool")
    }

    func test_even_scheduled_notification_received_sent() {
        // given
        fileName = "notificationWithScheduledCampaign.json"

        // when
        even_notification_received_sent { (event) in

            // then
            XCTAssertEqual(event.name, ScheduledNotificationDelivered.Constants.name)
        }
    }

    func test_even_triggered_notification_received_sent() {
        // given
        fileName = "notificationWithTriggeredCampaign.json"

        // when
        even_notification_received_sent { (event) in

            // then
            XCTAssertEqual(event.name, TriggeredNotificationRecieved.Constants.name)
        }
    }

    func even_notification_received_sent(assert: @escaping (OptimoveEvent) -> Void) {
        // given
        // fetch payload from a JSON
        let payload = try! JSONDecoder().decode(NotificationPayload.self, from: data)

        // and
        // create best attempt content
        let bestAttemptContent = notificationService.createBestAttemptBaseContent(
            request: UNNotificationRequest(
                identifier: "identifier",
                content: UNNotificationContent(),
                trigger: nil
            ),
            payload: payload
        )

        // when
        // check that content handler finally execute.
        let contentHandlerExpectation = expectation(description: "Content handler was not generated.")
        let contentHandler: (UNNotificationContent) -> Void = { content in
            contentHandlerExpectation.fulfill()
        }

        // check that delivery event sent.
        let optitrackExpectation = expectation(description: "Optitrack event was not generated.")
        mock.assetFunction = { event, completion in
            assert(event)
            completion()
            optitrackExpectation.fulfill()
        }

        // then
        try! notificationService.handleNotification(payload: payload,
                                                    optitrack: mock,
                                                    bestAttemptContent: bestAttemptContent!,
                                                    contentHandler: contentHandler)
        wait(for: [contentHandlerExpectation, optitrackExpectation], timeout: 1)
    }

}

final class MockOptitrackNSE: OptitrackNSE {

    var assetFunction: ((_ event: OptimoveEvent, _ completion: () -> Void) -> Void)?

    func report(event: OptimoveEvent, completion: @escaping () -> Void) throws {
        assetFunction?(event, completion)
    }
}
