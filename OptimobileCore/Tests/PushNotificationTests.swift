//  Copyright © 2023 Optimove. All rights reserved.

import OptimobileCore
import OptimoveTest
import XCTest

final class PushNotificationTests: XCTestCase, FileAccessible {
    var fileName: String = ""

    func test_decode_message() throws {
        fileName = "notification-message.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)
        XCTAssertEqual(notification.message.id, 1)
    }

    func test_decode_badge() throws {
        fileName = "notification-badge.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)
        XCTAssertEqual(notification.badge, 42)
    }

    func test_decode_buttons() throws {
        fileName = "notification-buttons.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)

        XCTAssertEqual(notification.buttons?.count, 3)
        XCTAssertEqual(notification.buttons?[0].id, "1")
        XCTAssertEqual(notification.buttons?[0].text, "action_1")

        XCTAssertEqual(notification.buttons?[1].id, "2")
        XCTAssertEqual(notification.buttons?[1].text, "action_2")
        XCTAssertEqual(notification.buttons?[1].icon?.id, "sys_icon_id")
        XCTAssertEqual(notification.buttons?[1].icon?.type, .system)

        XCTAssertEqual(notification.buttons?[2].id, "3")
        XCTAssertEqual(notification.buttons?[2].text, "action_3")
        XCTAssertEqual(notification.buttons?[2].icon?.id, "custom_icon_id")
        XCTAssertEqual(notification.buttons?[2].icon?.type, .custom)
    }

    func test_decode_image() throws {
        fileName = "notification-image.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)

        XCTAssertEqual(notification.attachment?.pictureUrl, "B04wM4Y7/b2f69e254879d69b58c7418468213762.jpeg")
    }

    func test_decode_background() throws {
        fileName = "notification-background.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)

        XCTAssertEqual(notification.aps.isBackground, true)
    }

    func test_decode_url() throws {
        fileName = "notification-url.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)

        XCTAssertEqual(notification.url?.absoluteString, "https://www.optimove.com")
    }

    func test_decode_deeplink() throws {
        fileName = "notification-deeplink.json"
        let decoder = JSONDecoder()
        let notification = try decoder.decode(PushNotification.self, from: data)

        XCTAssertEqual(notification.deeplink?.id, 1)
    }
}
