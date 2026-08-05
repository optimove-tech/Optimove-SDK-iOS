//  Copyright © 2026 Optimove. All rights reserved.

import Foundation
import UserNotifications

/// What should happen to a notification that arrives while the app is in the foreground.
enum ForegroundNotificationRoute: Equatable {
    /// Not one of ours, so it belongs to the delegate we replaced.
    case forwardToExistingDelegate
    /// One of ours, and the host app registered no foreground handler.
    case presentWithDefaultOptions
    /// One of ours, and the host app registered a handler to decide how to present it.
    case invokeForegroundHandler
}

/// What should happen to the user's response to a notification.
enum NotificationResponseRoute: Equatable {
    /// Not one of ours, so it belongs to the delegate we replaced.
    case forwardToExistingDelegate
    case handleDismissal
    case handleOpen
}

/// The routing rules of `OptimoveUserNotificationCenterDelegate`.
///
/// `UNUserNotificationCenter` permits exactly one delegate, so installing ours displaces
/// whatever the host app set. Everything that is not an Optimove notification therefore has
/// to be forwarded to the delegate we displaced — that rule is the whole reason the host
/// app keeps working, and until now it lived inline in two protocol methods that no test
/// can reach: `UNUserNotificationCenter.current()` raises
/// `bundleProxyForCurrentProcess is nil` in a test bundle, and neither `UNNotification` nor
/// `UNNotificationResponse` can be constructed. Keeping the rules here, as functions of the
/// payload alone, is what makes them verifiable.
enum NotificationDelegateRouting {
    static func route(
        willPresent notification: PushNotification,
        hasForegroundHandler: Bool
    ) -> ForegroundNotificationRoute {
        guard isOurs(notification) else {
            return .forwardToExistingDelegate
        }

        return hasForegroundHandler ? .invokeForegroundHandler : .presentWithDefaultOptions
    }

    @available(iOS 10.0, *)
    static func route(
        didReceive notification: PushNotification,
        actionIdentifier: String
    ) -> NotificationResponseRoute {
        guard isOurs(notification) else {
            return .forwardToExistingDelegate
        }

        return actionIdentifier == UNNotificationDismissActionIdentifier ? .handleDismissal : .handleOpen
    }

    /// A notification is ours when its payload carries an Optimove message id. Anything
    /// else — the host app's own pushes, another SDK's pushes, local notifications — is not
    /// ours to answer.
    private static func isOurs(_ notification: PushNotification) -> Bool {
        return notification.id != 0
    }
}
