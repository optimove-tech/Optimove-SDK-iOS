//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

/// `PushNotification.init(userInfo:)` runs on every notification the app receives, ours or
/// not, so it has to survive a payload it does not recognise rather than take the host app
/// down with it.
final class PushNotificationTests: XCTestCase {
    private func payload(message: Any?, url: String? = nil) -> [AnyHashable: Any] {
        var custom: [AnyHashable: Any] = [:]
        if let message = message {
            custom["a"] = ["k.message": message]
        }
        if let url = url {
            custom["u"] = url
        }

        return [
            "aps": ["alert": ["title": "Title", "body": "Body"]],
            "custom": custom,
        ]
    }

    // MARK: - Well-formed payloads

    func test_optimovePayload_parsesTheMessageId() {
        let notification = PushNotification(userInfo: payload(message: ["data": ["id": 42]]))

        XCTAssertEqual(notification.id, 42)
    }

    func test_optimovePayload_parsesTheDeepLinkUrl() {
        let notification = PushNotification(
            userInfo: payload(message: ["data": ["id": 42]], url: "https://example.com/offer")
        )

        XCTAssertEqual(notification.url, URL(string: "https://example.com/offer"))
    }

    func test_optimovePayload_exposesApsAndData() {
        let notification = PushNotification(userInfo: payload(message: ["data": ["id": 42]]))

        XCTAssertNotNil(notification.aps["alert"])
        XCTAssertNotNil(notification.data["k.message"])
    }

    // MARK: - Payloads that are not ours

    func test_noPayload_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: nil).id, 0)
    }

    func test_payloadWithoutAps_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: ["myAppsOwnKey": "value"]).id, 0)
    }

    func test_payloadWithoutCustom_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: ["aps": ["alert": "Sent by someone else"]]).id, 0)
    }

    func test_payloadWithoutAMessage_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: payload(message: nil)).id, 0)
    }

    // MARK: - Malformed payloads that used to crash

    func test_messageWithoutADataDictionary_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: payload(message: ["unexpected": "shape"])).id, 0)
    }

    func test_messageWithANonDictionaryData_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: payload(message: ["data": "not a dictionary"])).id, 0)
    }

    func test_messageWithoutAnId_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: payload(message: ["data": ["noId": true]])).id, 0)
    }

    func test_messageWithANonNumericId_hasNoMessageId() {
        XCTAssertEqual(PushNotification(userInfo: payload(message: ["data": ["id": "42"]])).id, 0)
    }
}
