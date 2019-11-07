//  Copyright © 2019 Optimove. All rights reserved.

import UIKit
import UserNotifications
import os.log
import OptimoveCore
import FirebaseMessaging

final class OptimoveNotificationHandler {

    private let synchronizer: Synchronizer
    private let deeplinkService: DeeplinkService

    init(synchronizer: Synchronizer,
         deeplinkService: DeeplinkService) {
        self.synchronizer = synchronizer
        self.deeplinkService = deeplinkService
    }
}

// MARK: - Private Methods
private extension OptimoveNotificationHandler {

    func reportNotification(response: UNNotificationResponse) {
        Logger.info("User react '\(response.actionIdentifier)' to a notification.")
        do {
            let event = try createEvent(from: response)
            let task = UIApplication.shared.beginBackgroundTask(withName: "Handling a notification reponse")
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                synchronizer.handle(.report(event: event))
                let delay: TimeInterval = min(UIApplication.shared.backgroundTimeRemaining, 2.0)
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    UIApplication.shared.endBackgroundTask(task)
                }
            default:
                UIApplication.shared.endBackgroundTask(task)
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    func createEvent(from response: UNNotificationResponse) throws -> OptimoveCoreEvent {
        let notificationDetails = response.notification.request.content.userInfo
        let data = try JSONSerialization.data(withJSONObject: notificationDetails)
        let notification = try JSONDecoder().decode(NotificationPayload.self, from: data)
        switch notification.campaign {
        case let campaign as ScheduledNotificationCampaign:
            return ScheduledNotificationOpened(
                bundleIdentifier: try Bundle.getApplicationNameSpace(),
                campaign: campaign
            )
        case let campaign as TriggeredNotificationCampaign:
            return TriggeredNotificationOpened(
                bundleIdentifier: try Bundle.getApplicationNameSpace(),
                campaign: campaign
            )
        default:
            throw GuardError.custom(
                """
                The campaign of type \(notification.campaign?.type.rawValue ?? "nil") is not supported.
                Probably this is a test notification.
                """
            )
        }
    }

    func handleDeepLinkDelegation(_ response: UNNotificationResponse) {
        do {
            let userInfo = response.notification.request.content.userInfo
            let dynamicLink: String = try cast(userInfo[OptimoveKeys.Notification.dynamikLink.rawValue])
            let urlComp = try unwrap(URLComponents(string: dynamicLink))
            let params: [String: String]? = urlComp.queryItems?.reduce(into: [String: String](), { (result, next) in
                result.updateValue(next.value ?? "", forKey: next.name)
            })
            deeplinkService.setDeepLinkComponents(
                OptimoveDeepLinkComponents(
                    screenName: String(urlComp.path.dropFirst()),
                    parameters: params
                )  // The dropFirst() is to eliminate the "/" prefix of the path
            )
        } catch {
            Logger.error(error.localizedDescription)
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
        Messaging.messaging().appDidReceiveMessage(notification.request.content.userInfo)
        completionHandler([.alert, .sound, .badge])
    }

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        reportNotification(response: response)
        if isNotificationOpened(response: response) {
            handleDeepLinkDelegation(response)
        }
        completionHandler()
    }
}

// MARK: - Helper methods
extension OptimoveNotificationHandler {
    private func isNotificationOpened(response: UNNotificationResponse) -> Bool {
        return response.actionIdentifier == UNNotificationDefaultActionIdentifier
    }
}
