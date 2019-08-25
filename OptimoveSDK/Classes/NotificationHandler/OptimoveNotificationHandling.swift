//  Copyright © 2019 Optimove. All rights reserved.

import UserNotifications
import UIKit

protocol OptimoveNotificationHandling {
    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    )

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping (() -> Void)
    )
}
