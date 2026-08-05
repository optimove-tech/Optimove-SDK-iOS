//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UserNotifications

@available(iOS 10.0, *)
class OptimoveUserNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// The delegate this one was installed over. Everything that is not an Optimove
    /// notification is forwarded to it, so that replacing the host app's delegate does not
    /// take their notification handling away.
    let existingDelegate: UNUserNotificationCenterDelegate?

    /// - Parameter existingDelegate: the delegate currently installed on the notification
    ///   center, read by the caller. Injected rather than read from
    ///   `UNUserNotificationCenter.current()` here, because that call raises in a test
    ///   bundle and made this class impossible to construct in a test.
    init(existingDelegate: UNUserNotificationCenterDelegate?) {
        if let ours = existingDelegate as? OptimoveUserNotificationCenterDelegate {
            // Never chain to another delegate of ours. Nesting would make us handle each
            // notification once per layer, and forward each one to the host app's delegate
            // as many times over.
            self.existingDelegate = ours.existingDelegate
        } else {
            self.existingDelegate = existingDelegate
        }

        super.init()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let push = PushNotification(userInfo: notification.request.content.userInfo, response: nil)
        // Read once: `config` is replaced wholesale when a delayed configuration completes.
        let foregroundHandler = Optimobile.sharedInstance.config.pushReceivedInForegroundHandlerBlock

        switch NotificationDelegateRouting.route(willPresent: push, hasForegroundHandler: foregroundHandler != nil) {
        case .forwardToExistingDelegate:
            chainCenter(center, willPresent: notification, with: completionHandler)

        case .presentWithDefaultOptions:
            completionHandler(.alert)

        case .invokeForegroundHandler:
            guard let foregroundHandler = foregroundHandler else {
                // Unreachable: the route is derived from this very value. Present rather
                // than leave the completion handler uncalled, which would hang the banner.
                completionHandler(.alert)
                return
            }

            foregroundHandler(push, completionHandler)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let push = PushNotification(userInfo: userInfo, response: response)

        switch NotificationDelegateRouting.route(didReceive: push, actionIdentifier: response.actionIdentifier) {
        case .forwardToExistingDelegate:
            chainCenter(center, didReceive: response, with: completionHandler)

        case .handleDismissal:
            let handled = Optimobile.sharedInstance.pushHandleDismissed(withUserInfo: userInfo, response: response)
            if handled {
                completionHandler()
            } else {
                chainCenter(center, didReceive: response, with: completionHandler)
            }

        case .handleOpen:
            let handled = Optimobile.sharedInstance.pushHandleOpen(withUserInfo: userInfo, response: response)
            if handled {
                completionHandler()
            } else {
                chainCenter(center, didReceive: response, with: completionHandler)
            }
        }
    }

    fileprivate func chainCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, with completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let selector = #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))

        guard let existingDelegate = existingDelegate, existingDelegate.responds(to: selector) else {
            completionHandler(.alert)
            return
        }

        existingDelegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
    }

    fileprivate func chainCenter(_ center: UNUserNotificationCenter, didReceive notificationResponse: UNNotificationResponse, with completionHandler: @escaping () -> Void) {
        let selector = #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))

        guard let existingDelegate = existingDelegate, existingDelegate.responds(to: selector) else {
            completionHandler()
            return
        }

        existingDelegate.userNotificationCenter?(center, didReceive: notificationResponse, withCompletionHandler: completionHandler)
    }
}
