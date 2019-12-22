//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications

protocol NotificationPermissionFetcher {
    func fetch(completion: @escaping (Bool) -> Void)
}

final class NotificationPermissionFetcherImpl: NotificationPermissionFetcher {

    func fetch(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if #available(iOS 12.0, *) {
                let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                completion(isAuthorized)
            } else {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }
}
