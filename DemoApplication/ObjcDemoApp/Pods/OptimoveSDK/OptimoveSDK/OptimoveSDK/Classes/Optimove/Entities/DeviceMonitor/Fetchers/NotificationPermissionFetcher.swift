import Foundation
import UserNotifications

class NotificationPermissionFetcher: Fetchable {
    func fetch(completionHandler: @escaping ResultBlockWithBool) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .notDetermined {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
}
