import UIKit
import UserNotifications
import os.log

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
        configureUserNotificationsDismissCategory()
    }
}

// MARK: - Private Methods
private extension OptimoveNotificationHandler {

    /// That category used for handling a custom dismiss action.
    /// A new received OptiPush notification will have this identifier, so in this case we can track the user's response.
    func configureUserNotificationsDismissCategory() {
        let category = UNNotificationCategory(
            identifier: NotificationCategoryIdentifiers.dismiss,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

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
            let bgtask = UIApplication.shared.beginBackgroundTask(withName: "reregister")
            OptiLoggerMessages.logRequestToRegister()
            DispatchQueue.global().async { [optimove] in
                optimove.performRegistration()
                DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0)) {
                    completion(.newData)
                    UIApplication.shared.endBackgroundTask(bgtask)
                }
            }
            
        case .ping:
            let bgtask = UIApplication.shared.beginBackgroundTask(withName: "ping")
            OptiLoggerMessages.logRequestToPing()
            do {
                let event = try coreEventFactory.createEvent(.ping)
                optimove.reportEvent(event)
            } catch {
                OptiLoggerMessages.logError(error: error)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 1.0)) { [optimove] in
                optimove.dispatchQueuedEventsNow()
            }
            OptiLoggerMessages.logRemainBackgroundTime(
                backgroundTimeRemaining: UIApplication.shared.backgroundTimeRemaining
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 3.0)) {
                
                completion(.newData)
                UIApplication.shared.endBackgroundTask(bgtask)
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
                options: .customDismissAction
            )
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.setNotificationCategories([category])
            notificationCenter.getNotificationCategories { (categories) in
                categories.forEach({ (categoty) in
                    os_log("Category registred: %{PRIVATE}@", log: OSLog.consoleStream, type: .debug, categoty.identifier)
                })
                os_log("User actions successfully added.", log: OSLog.consoleStream, type: .debug)
                completion(.newData)
            }
        }
    }

    func reportNotification(response: UNNotificationResponse) {
        OptiLoggerMessages.logUserReactToNotification()
        OptiLoggerMessages.logUserReaction(userResponseToNotification: response.actionIdentifier)

        let notificationDetails = response.notification.request.content.userInfo

        guard let campaignDetails = CampaignDetails.extractCampaignDetails(from: notificationDetails) else {
            OptiLoggerMessages.logCampignDetailsCouldNotBeExtracted()
            return
        }

        let task = UIApplication.shared.beginBackgroundTask(withName: "notification reponse")
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            optimove.reportEvent(NotificationDismissedEvent(campaignDetails: campaignDetails))
            optimove.dispatchQueuedEventsNow()
            OptiLoggerMessages.logRemainBackgroundTime(
                backgroundTimeRemaining: UIApplication.shared.backgroundTimeRemaining
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0)) {
                UIApplication.shared.endBackgroundTask(task)
            }

        case UNNotificationDefaultActionIdentifier:
            optimove.reportEvent(NotificationOpenedEvent(campaignDetails: campaignDetails))
            optimove.dispatchQueuedEventsNow()
            OptiLoggerMessages.logRemainBackgroundTime(
                backgroundTimeRemaining: UIApplication.shared.backgroundTimeRemaining
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0)) {
                UIApplication.shared.endBackgroundTask(task)
            }

        default: UIApplication.shared.endBackgroundTask(task)
        }
    }

    func handleDeepLinkDelegation(_ response: UNNotificationResponse) {
        guard
            let dynamicLink = response.notification.request.content.userInfo[
            OptimoveKeys.Notification.dynamikLink.rawValue] as? String,
            let urlComp = URLComponents(string: dynamicLink) else { return }
        var params: [String: String]? = nil
        if let queryItems = urlComp.queryItems {
            params = [:]
            for qItem in queryItems {
                guard let value = qItem.value else {
                    params![qItem.name] = ""
                    continue
                }
                params![qItem.name] = value
            }
        }

        optimove.deepLinkComponents = OptimoveDeepLinkComponents(
            screenName: String(urlComp.path.dropFirst()),
            parameters: params
        )  // The dropFirst() is to eliminate the "/" prefix of the path
    }

}

extension OptimoveNotificationHandler: OptimoveNotificationHandling {

    func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        optimove.startUrgentInitProcess { (success) in
            guard success else {
                OptiLoggerMessages.logUrgentInitFailed()
                return
            }
            OptiLoggerMessages.logUrgentInitSuccess()
            
            OptiLoggerMessages.logAnalyzenotification()
            guard userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true" else {
                OptiLoggerMessages.logCommandNotificationFailure()
                didComplete(.newData)
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: userInfo)
                let decoder = JSONDecoder()
                let command = try decoder.decode(OptimoveSdkCommand.self, from: data)
                self.handleSdkCommand(command: command, completionHandler: didComplete)
            } catch {
                OptiLoggerMessages.logCommandNotificationFailure()
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
                OptiLoggerMessages.logUrgentInitFailed()
                return
            }
            OptiLoggerMessages.logUrgentInitSuccess()

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
