//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications

protocol NotificationPermissionFetcher {
    func fetch(completion: @escaping ResultBlockWithBool)
}

final class NotificationPermissionFetcherImpl: NotificationPermissionFetcher {

    func fetch(completion: @escaping ResultBlockWithBool) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .notDetermined {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
