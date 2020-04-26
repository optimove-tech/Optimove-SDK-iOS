//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
import UserNotifications
@testable import OptimoveNotificationServiceExtension

class OptimoveNotificationServiceExtensionTests: OptimoveTestCase, FileAccessible {

    var fileName: String = "notificationWithScheduledCampaign.json"
    let networking = OptistreamNetworkingMock()
    var notificationService: OptimoveNotificationServiceExtension!

    override func setUp() {
        notificationService = OptimoveNotificationServiceExtension(appBundleId: "com.apple.dt.xctest.tool")
    }

    func test_even_scheduled_notification_received_sent() throws {
        // given
        prefillStorageAsVisitor()
        fileName = "notificationWithScheduledCampaign.json"

        // when
        try even_notification_received_sent { (event) in

            // then
            XCTAssertEqual(event.event, ScheduledNotificationDelivered.Constants.name)
        }
    }

    func test_even_triggered_notification_received_sent() throws {
        // given
        prefillStorageAsVisitor()
        fileName = "notificationWithTriggeredCampaign.json"

        // when
        try even_notification_received_sent { (event) in

            // then
            XCTAssertEqual(event.event, TriggeredNotificationRecieved.Constants.name)
        }
    }

    func even_notification_received_sent(assert: @escaping (OptistreamEvent) -> Void) throws {
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
        networking.assetOneEventFunction = { event, completion in
            assert(event)
            completion(.success(OptistreamResponse(status: "", message: "")))
            optitrackExpectation.fulfill()
        }

        // then
        try notificationService.handleNotification(
            payload: payload,
            networking: networking,
            builder: OptistreamEventBuilder(
                configuration: ConfigurationFixture.build().optitrack,
                storage: storage
            ),
            bestAttemptContent: bestAttemptContent!,
            contentHandler: contentHandler
        )
        wait(for: [contentHandlerExpectation, optitrackExpectation], timeout: 1)
    }

}
