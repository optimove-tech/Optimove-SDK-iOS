//  Copyright © 2019 Optimove. All rights reserved.

import UIKit
import UserNotifications
import os.log
import OptimoveCore

final class OptimoveNotificationHandler {

    private let storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory
    private let optimove: Optimove

    required init(
        storage: OptimoveStorage,
        coreEventFactory: CoreEventFactory,
        optimove: Optimove) {
        self.storage = storage
        self.coreEventFactory = coreEventFactory
        self.optimove = optimove
    }
}

// MARK: - Private Methods
private extension OptimoveNotificationHandler {

    func handleSdkCommand(
        command: OptimoveSdkCommand,
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        switch command {
        case let .common(common):
            handleCommonCommand(common, completion: completionHandler)
        case let .parameterized(parameter):
            handleParametrizedCommand(parameter, completion: completionHandler)
        }
    }

    func handleCommonCommand(
        _ common: (OptimoveSdkCommand.Common),
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        switch common {
        case .reregister:
            Logger.debug("Request to reregister.")
            let bgtask = UIApplication.shared.beginBackgroundTask(withName: "reregister")
            DispatchQueue.global().async { [optimove] in
                optimove.performRegistration()
                let delay: TimeInterval = min(UIApplication.shared.backgroundTimeRemaining, 2.0)
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    completion(.newData)
                    UIApplication.shared.endBackgroundTask(bgtask)
                }
            }

        case .ping:
            Logger.debug("Request to ping.")
            do {
                let event = try coreEventFactory.createEvent(.ping)
                optimove.reportEvent(event)
                let bgtask = UIApplication.shared.beginBackgroundTask(withName: "ping")
                DispatchQueue.global().async { [optimove] in
                    optimove.dispatchQueuedEventsNow()
                    let delay: TimeInterval = min(UIApplication.shared.backgroundTimeRemaining, 3.0)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        completion(.newData)
                        UIApplication.shared.endBackgroundTask(bgtask)
                    }
                }
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    func handleParametrizedCommand(
        _ parameter: OptimoveSdkCommand.Parameterized,
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        switch parameter {
        case let .newNotificationCategory(newCategory):
            let actions = newCategory.actions.map { action in
                return UNNotificationAction(
                    identifier: action.identifier,
                    title: action.title
                )
            }
            let category = UNNotificationCategory(
                identifier: newCategory.categoryIdentifier,
                actions: actions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.setNotificationCategories([category])
            notificationCenter.getNotificationCategories { (categories) in
                categories.forEach({ (categoty) in
                    Logger.debug("Category registred: \(categoty.identifier)")
                })
                Logger.debug("User actions successfully added.")
                completion(.newData)
            }
        }
    }

    func reportNotification(response: UNNotificationResponse) {
        Logger.info("User react '\(response.actionIdentifier)' to a notification.")
        do {
            let event = try createEvent(from: response)
            let task = UIApplication.shared.beginBackgroundTask(withName: "Handling a notification reponse")
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                optimove.reportEvent(event)
                optimove.dispatchQueuedEventsNow()
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
            throw GuardError.custom("The campaign of type \(notification.campaign.type.rawValue) is not supported.")
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
            optimove.deepLinkComponents = OptimoveDeepLinkComponents(
                screenName: String(urlComp.path.dropFirst()),
                parameters: params
            )  // The dropFirst() is to eliminate the "/" prefix of the path
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}

extension OptimoveNotificationHandler: OptimoveNotificationHandling {

    func isOptimoveSdkCommand(userInfo: [AnyHashable: Any]) -> Bool {
        return userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true"
    }

    func isOptipush(notification: UNNotification) -> Bool {
        return notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true"
    }

    func willPresent(
        notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
        completionHandler([.alert, .sound, .badge])
    }

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        optimove.startUrgentInitProcess { (success) in
            guard success else {
                Logger.error("Urgent initializtion failed")
                return
            }
            Logger.info("Urgent Initialization success")

            guard self.isOptimoveSdkCommand(userInfo: userInfo) else {
                Logger.debug("The notification do not contains SDK command.")
                didComplete(.newData)
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: userInfo)
                let decoder = JSONDecoder()
                let command = try decoder.decode(OptimoveSdkCommand.self, from: data)
                self.handleSdkCommand(command: command, completionHandler: didComplete)
            } catch {
                Logger.error("Could not parse SDK command. Reason: \(error.localizedDescription)")
                didComplete(.newData)
            }
        }
    }

    func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping ResultBlock
    ) {
        optimove.startUrgentInitProcess { (success) in
            guard success else {
                Logger.error("Urgent initializtion failed")
                return
            }
            Logger.info("Urgent Initialization success")

            self.reportNotification(response: response)
            if self.isNotificationOpened(response: response) {
                self.handleDeepLinkDelegation(response)
            }
            completionHandler()
        }
    }
}

// MARK: - Helper methods
extension OptimoveNotificationHandler {
    private func isNotificationOpened(response: UNNotificationResponse) -> Bool {
        return response.actionIdentifier == UNNotificationDefaultActionIdentifier
    }
}
