//  Copyright © 2019 Optimove. All rights reserved.

import UserNotifications
import UIKit

protocol OptimoveNotificationHandling {

    func isOptimoveSdkCommand(userInfo: [AnyHashable: Any]) -> Bool
    func isOptipush(notification: UNNotification) -> Bool

    func willPresent(
        notification: UNNotification,
        withCompletionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    )

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    )

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping (() -> Void)
    )
}
