//  Copyright © 2019 Optimove. All rights reserved.

import UIKit
import UserNotifications
import os.log
import OptimoveCore

final class OptimoveNotificationHandler {

    private let synchronizer: Pipeline
    private let deeplinkService: DeeplinkService

    init(synchronizer: Pipeline,
         deeplinkService: DeeplinkService) {
        self.synchronizer = synchronizer
        self.deeplinkService = deeplinkService
    }
}

// MARK: - Private Methods
private extension OptimoveNotificationHandler {

    func reportNotification(actionIdentifier: String, notification: NotificationPayload) {
        tryCatch {
            switch actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                let event = try createEvent(from: notification)
                synchronizer.deliver(.report(events: [event]))
            default:
                break
            }
        }
    }

    func createEvent(from notification: NotificationPayload) throws -> Event {
        guard let campaign = notification.campaign else {
            throw GuardError.custom(
                """
                The campaign of type is not supported.
                Probably this is a test notification.
                """
            )
        }
        return NotificationOpenedEvent(
            bundleIdentifier: try Bundle.getApplicationNameSpace(),
            notificationType: campaign.type,
            identityToken: campaign.identityToken,
            requestId: notification.eventVariables.requestId
        )
    }

    func handleDeepLinkDelegation(from notification: NotificationPayload) {
        guard let deepLink = notification.deepLink else {
            Logger.debug("Notification does not contain a dynamic link.")
            return
        }
        tryCatch {
            let urlComp = try unwrap(URLComponents(url: deepLink, resolvingAgainstBaseURL: true))
            let params: [String: String]? = urlComp.queryItems?.reduce(into: [String: String](), { (result, next) in
                result.updateValue(next.value ?? "", forKey: next.name)
            })
            // The dropFirst() is to eliminate the "/" prefix of the path
            let screenName = String(urlComp.path.dropFirst())
            Logger.debug("Sending a deeplink with screenName: \(screenName) and params: \(String(describing: params))")
            deeplinkService.setDeepLinkComponents(
                OptimoveDeepLinkComponents(
                    screenName: screenName,
                    parameters: params
                )
            )
        }
    }

}

extension OptimoveNotificationHandler: OptimoveNotificationHandling {

    func isOptipush(notification: UNNotification) -> Bool {
        return notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true"
    }

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        didComplete(.noData)
    }

    func willPresent(
        notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
        completionHandler([.alert, .sound, .badge])
    }

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        tryCatch {
            let actionIdentifier = response.actionIdentifier
            Logger.info("User react '\(actionIdentifier)' to a notification.")
            let notification = try verifyAndCreateNotificationPayload(response)
            reportNotification(actionIdentifier: actionIdentifier, notification: notification)
            if isNotificationOpened(actionIdentifier: actionIdentifier) {
                handleDeepLinkDelegation(from: notification)
            }
        }
        completionHandler()
    }
}


extension OptimoveNotificationHandler {

    func verifyAndCreateNotificationPayload(_ response: UNNotificationResponse) throws -> NotificationPayload {
        let notificationDetails = response.notification.request.content.userInfo
        let data = try JSONSerialization.data(withJSONObject: notificationDetails)
        return try JSONDecoder().decode(NotificationPayload.self, from: data)
    }

    func isNotificationOpened(actionIdentifier: String) -> Bool {
        return actionIdentifier == UNNotificationDefaultActionIdentifier
    }
}
