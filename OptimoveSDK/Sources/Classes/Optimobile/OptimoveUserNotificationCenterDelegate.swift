//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UserNotifications

@available(iOS 10.0, *)
class OptimoveUserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    let existingDelegate: UNUserNotificationCenterDelegate?

    override init() {
        existingDelegate = UNUserNotificationCenter.current().delegate
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let push = PushNotification(userInfo: notification.request.content.userInfo, response: nil)

        if push.id == 0 {
            chainCenter(center, willPresent: notification, with: completionHandler)
            return
        }

        if Optimobile.sharedInstance.config.pushReceivedInForegroundHandlerBlock == nil {
            completionHandler(.alert)
            return
        }

        Optimobile.sharedInstance.config.pushReceivedInForegroundHandlerBlock?(push, completionHandler)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if userInfo["aps"] == nil {
            chainCenter(center, didReceive: response, with: completionHandler)
            return
        }

        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            let handled = Optimobile.sharedInstance.pushHandleDismissed(withUserInfo: userInfo, response: response)
            if !handled {
                chainCenter(center, didReceive: response, with: completionHandler)
                return
            }

            completionHandler()
            return
        }

        let handled = Optimobile.sharedInstance.pushHandleOpen(withUserInfo: userInfo, response: response)

        if !handled {
            chainCenter(center, didReceive: response, with: completionHandler)
            return
        }

        completionHandler()
    }

    fileprivate func chainCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, with completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if existingDelegate != nil && existingDelegate?.responds(to: #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))) == true {
            self.existingDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            return
        }

        completionHandler(.alert)
    }

    fileprivate func chainCenter(_ center: UNUserNotificationCenter, didReceive notificationResponse: UNNotificationResponse, with completionHandler: @escaping () -> Void) {
        if existingDelegate != nil && existingDelegate?.responds(to: #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))) == true {
            self.existingDelegate?.userNotificationCenter?(center, didReceive: notificationResponse, withCompletionHandler: completionHandler)
            return
        }

        completionHandler()
    }
}
