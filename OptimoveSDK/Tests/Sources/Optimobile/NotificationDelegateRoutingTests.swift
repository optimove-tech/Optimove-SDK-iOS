//  Copyright © 2026 Optimove. All rights reserved.

import UserNotifications
import XCTest
@testable import OptimoveSDK

private class HostAppDelegate: NSObject, UNUserNotificationCenterDelegate {}

/// Installing our delegate displaces the host app's, so anything that is not an Optimove
/// notification has to be forwarded to theirs. These tests pin that rule down.
final class NotificationDelegateRoutingTests: XCTestCase {
    // MARK: - Payloads

    /// What the Optimove push service sends. `PushNotification` reads the message id out of
    /// `custom.a.k.message.data.id`, and a non-zero id is what marks a notification as ours.
    private func optimoveNotification(id: Int = 42) -> PushNotification {
        return PushNotification(userInfo: [
            "aps": ["alert": ["title": "Title", "body": "Body"]],
            "custom": ["a": ["k.message": ["data": ["id": id]]]],
        ])
    }

    /// A remote notification from somewhere else — the host app's own push provider, or
    /// another SDK. It has an `aps` payload like ours, and no Optimove message id.
    private func foreignRemoteNotification() -> PushNotification {
        return PushNotification(userInfo: [
            "aps": ["alert": "Sent by someone else"],
            "myAppsOwnKey": "value",
        ])
    }

    /// A local notification scheduled by the host app. No `aps` payload at all.
    private func localNotification() -> PushNotification {
        return PushNotification(userInfo: ["myAppsOwnKey": "value"])
    }

    // MARK: - Foreground presentation

    func test_foreignRemoteNotification_isForwardedToTheDelegateWeReplaced() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(willPresent: foreignRemoteNotification(), hasForegroundHandler: false),
            .forwardToExistingDelegate
        )
    }

    func test_foreignRemoteNotification_isForwardedEvenWhenAForegroundHandlerIsRegistered() {
        // The host app's foreground handler is for Optimove notifications. Registering one
        // must not start swallowing other people's notifications.
        XCTAssertEqual(
            NotificationDelegateRouting.route(willPresent: foreignRemoteNotification(), hasForegroundHandler: true),
            .forwardToExistingDelegate
        )
    }

    func test_localNotification_isForwardedToTheDelegateWeReplaced() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(willPresent: localNotification(), hasForegroundHandler: true),
            .forwardToExistingDelegate
        )
    }

    func test_optimoveNotification_withoutAForegroundHandler_isPresentedByUs() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(willPresent: optimoveNotification(), hasForegroundHandler: false),
            .presentWithDefaultOptions
        )
    }

    func test_optimoveNotification_withAForegroundHandler_asksTheHandler() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(willPresent: optimoveNotification(), hasForegroundHandler: true),
            .invokeForegroundHandler
        )
    }

    // MARK: - Responses

    func test_foreignRemoteNotificationResponse_isForwardedToTheDelegateWeReplaced() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(
                didReceive: foreignRemoteNotification(),
                actionIdentifier: UNNotificationDefaultActionIdentifier
            ),
            .forwardToExistingDelegate
        )
    }

    func test_foreignRemoteNotificationDismissal_isForwardedToTheDelegateWeReplaced() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(
                didReceive: foreignRemoteNotification(),
                actionIdentifier: UNNotificationDismissActionIdentifier
            ),
            .forwardToExistingDelegate
        )
    }

    func test_localNotificationResponse_isForwardedToTheDelegateWeReplaced() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(
                didReceive: localNotification(),
                actionIdentifier: UNNotificationDefaultActionIdentifier
            ),
            .forwardToExistingDelegate
        )
    }

    func test_optimoveNotificationTap_isHandledAsAnOpen() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(
                didReceive: optimoveNotification(),
                actionIdentifier: UNNotificationDefaultActionIdentifier
            ),
            .handleOpen
        )
    }

    func test_optimoveNotificationCustomAction_isHandledAsAnOpen() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(didReceive: optimoveNotification(), actionIdentifier: "reply"),
            .handleOpen
        )
    }

    func test_optimoveNotificationDismissal_isHandledAsADismissal() {
        XCTAssertEqual(
            NotificationDelegateRouting.route(
                didReceive: optimoveNotification(),
                actionIdentifier: UNNotificationDismissActionIdentifier
            ),
            .handleDismissal
        )
    }

    // MARK: - Chaining

    func test_delegate_chainsToTheDelegateItReplaced() {
        let hostApp = HostAppDelegate()

        let ours = OptimoveUserNotificationCenterDelegate(existingDelegate: hostApp)

        XCTAssertTrue(ours.existingDelegate === hostApp)
    }

    func test_delegate_doesNotChainToAnotherDelegateOfOurs() {
        let hostApp = HostAppDelegate()
        let firstInstall = OptimoveUserNotificationCenterDelegate(existingDelegate: hostApp)

        let secondInstall = OptimoveUserNotificationCenterDelegate(existingDelegate: firstInstall)

        XCTAssertTrue(
            secondInstall.existingDelegate === hostApp,
            "Nesting our own delegates would handle each notification once per layer"
        )
    }

    func test_delegate_toleratesTheHostAppHavingNoDelegate() {
        let ours = OptimoveUserNotificationCenterDelegate(existingDelegate: nil)

        XCTAssertNil(ours.existingDelegate)
    }
}
