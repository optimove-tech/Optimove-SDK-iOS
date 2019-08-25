//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications

final class NotificationPermissionFetcher: Fetchable {

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
