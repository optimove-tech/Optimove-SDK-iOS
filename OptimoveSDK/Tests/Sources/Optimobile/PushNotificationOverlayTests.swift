//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

final class PushNotificationOverlayTests: XCTestCase {

    private func push(deepLink: [String: Any]?) -> PushNotification {
        var data: [String: Any] = [:]
        data["k.deepLink"] = deepLink
        return PushNotification(userInfo: ["aps": ["content-available": 1], "custom": ["a": data]])
    }

    func test_readsTheNextFetchFromAScheduledSignal() {
        let notification = push(deepLink: ["type": 3, "data": ["nextFetchInSeconds": 2040]])

        XCTAssertEqual(notification.overlayScheduledNextFetchInSeconds, 2040)
        XCTAssertFalse(notification.isOverlayTriggeredSignal)
    }

    func test_readsASignalFor0() {
        XCTAssertEqual(push(deepLink: ["type": 3, "data": ["nextFetchInSeconds": 0]]).overlayScheduledNextFetchInSeconds, 0)
    }

    func test_ignoresAScheduledSignalWithoutTheValue() {
        XCTAssertNil(push(deepLink: ["type": 3]).overlayScheduledNextFetchInSeconds)
        XCTAssertNil(push(deepLink: ["type": 3, "data": [:]]).overlayScheduledNextFetchInSeconds)
    }

    func test_aTriggeredSignalIsNotAScheduledSignal() {
        let notification = push(deepLink: ["type": 2])

        XCTAssertTrue(notification.isOverlayTriggeredSignal)
        XCTAssertNil(notification.overlayScheduledNextFetchInSeconds)
    }

    func test_aPushWithoutADeepLinkIsNotAScheduledSignal() {
        let notification = push(deepLink: nil)

        XCTAssertFalse(notification.isOverlayTriggeredSignal)
        XCTAssertNil(notification.overlayScheduledNextFetchInSeconds)
    }
}
