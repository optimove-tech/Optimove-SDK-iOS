import UIKit
import FirebaseDynamicLinks
import UserNotifications

enum NotificationState
{
    case opened
    case delivered
    case dismissed
}

class OptimoveNotificationHandler
{
    required init()
    {
        configureUserNotificationsDismissCategory()
    }
    
    
    private func configureUserNotificationsDismissCategory()
    {
        let category = UNNotificationCategory(identifier: NotificationCategoryIdentifiers.dismiss,
                                              actions: [],
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func buildNotificationContent(_ userInfo: [AnyHashable : Any],
                                          _ campaignDetails: CampaignDetails?,
                                          _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = userInfo[OptimoveKeys.Notification.title.rawValue] as? String ?? Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        content.body = userInfo[OptimoveKeys.Notification.body.rawValue] as? String ?? ""
        content.categoryIdentifier = NotificationCategoryIdentifiers.dismiss
        if campaignDetails != nil {
            insertCampaignDetails(from: campaignDetails!, to: content)
        }
        content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] = "true"
        
        insertLongDeepLinkUrl(from:userInfo, to: content)
        {
            let collapseId = (Bundle.main.bundleIdentifier ?? "") + "_" + (userInfo[OptimoveKeys.Notification.collapseId.rawValue] as? String ?? "OptipushDefaultCollapseID")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.6, repeats: false)
            let request = UNNotificationRequest(identifier: collapseId,
                                                content: content,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
            completionHandler(.newData)
        }
    }
    
    //MARK: - Private Methods
    
    private func handleSdkCommand(command: OptimoveSdkCommand,
                                  completionHandler:@escaping (UIBackgroundFetchResult) -> Void)
    {
        switch command {
        case .reregister:
            let bgtask = UIApplication.shared.beginBackgroundTask(withName: "reregister")
            OptiLogger.debug("request to reregister")
            DispatchQueue.global().async {
                Optimove.sharedInstance.performRegistration()
                DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0))
                {
                    completionHandler(.newData)
                    UIApplication.shared.endBackgroundTask(bgtask)
                }
            }
            
        case .ping:
            let bgtask = UIApplication.shared.beginBackgroundTask(withName: "ping")
            OptiLogger.debug("request to ping")
            Optimove.sharedInstance.reportEvent(PingEvent())
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 1.0))
            {
                Optimove.sharedInstance.dispatchQueuedEventsNow()
            }
            OptiLogger.debug("background time remaining is \(UIApplication.shared.backgroundTimeRemaining)")
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 3.0))
            {
                
                completionHandler(.newData)
                UIApplication.shared.endBackgroundTask(bgtask)
            }
        }
    }
    
    
    private func reportNotification(response: UNNotificationResponse)
    {
        OptiLogger.debug("User react to notification")
        OptiLogger.debug("Action = \(response.actionIdentifier)")
        
        let notificationDetails = response.notification.request.content.userInfo
        
        guard let campaignDetails = CampaignDetails.extractCampaignDetails(from: notificationDetails) else {
            OptiLogger.error("campaign details could not be extracted")
            return
        }
        
        let task = UIApplication.shared.beginBackgroundTask(withName: "notification reponse")
        switch response.actionIdentifier
        {
        case UNNotificationDismissActionIdentifier:
            Optimove.sharedInstance.reportEvent(NotificationDismissed(campaignDetails: campaignDetails))
            Optimove.sharedInstance.dispatchQueuedEventsNow()
            OptiLogger.debug("background time remaining is \(UIApplication.shared.backgroundTimeRemaining)")
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0))
            {
                UIApplication.shared.endBackgroundTask(task)
            }
            
            
        case UNNotificationDefaultActionIdentifier:
            Optimove.sharedInstance.reportEvent(NotificationOpened(campaignDetails: campaignDetails))
            Optimove.sharedInstance.dispatchQueuedEventsNow()
            OptiLogger.debug("background time remaining is \(UIApplication.shared.backgroundTimeRemaining)")
            DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0))
            {
                UIApplication.shared.endBackgroundTask(task)
            }
            
            
        default: UIApplication.shared.endBackgroundTask(task)
        }
    }
    
    private func insertLongDeepLinkUrl(from userInfo: [AnyHashable : Any],
                                       to content: UNMutableNotificationContent,
                                       withCompletionHandler completionHandler: @escaping ResultBlock)
    {
        if let url = extractDeepLink(from: userInfo)
        {
            DynamicLinks.dynamicLinks().handleUniversalLink(url)
            { (longUrl, error) in
                if error != nil
                {
                    OptiLogger.debug("Deep link could not be extracted. error: \(error!.localizedDescription)")
                }
                else
                {
                    content.userInfo[OptimoveKeys.Notification.dynamikLink.rawValue] = longUrl?.url?.absoluteString
                }
                completionHandler()
            }
            completionHandler()
        }
        else
        {
            completionHandler()
        }
    }
    
    private func insertCampaignDetails(from campaignDetails: CampaignDetails,  to content: UNMutableNotificationContent)
    {
        content.userInfo[OptimoveKeys.Notification.campaignId.rawValue]     = campaignDetails.campaignId
        content.userInfo[OptimoveKeys.Notification.actionSerial.rawValue]   = campaignDetails.actionSerial
        content.userInfo[OptimoveKeys.Notification.templateId.rawValue]     = campaignDetails.templateId
        content.userInfo[OptimoveKeys.Notification.engagementId.rawValue]   = campaignDetails.engagementId
        content.userInfo[OptimoveKeys.Notification.campaignType.rawValue]   = campaignDetails.campaignType
    }
    
    private func handleDeepLinkDelegation(_ response: UNNotificationResponse) {
        if let dynamicLink =  response.notification.request.content.userInfo[OptimoveKeys.Notification.dynamikLink.rawValue] as? String
        {
            if let absoluteUrl = URL(string: dynamicLink)
            {
                OptiLogger.debug("store dynamic link of message")
                if let screenName = absoluteUrl.pathComponents.last {
                    let query = absoluteUrl.queryParameters
                    Optimove.sharedInstance.deepLinkComponents = OptimoveDeepLinkComponents(screenName: screenName, query: query)
                }
            }
        }
    }
    
    private func extractDeepLink(from userInfo:  [AnyHashable : Any]) -> URL?
    {
        if let dl           = userInfo[OptimoveKeys.Notification.dynamicLinks.rawValue] as? String ,
            let data        = dl.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data, options:[.allowFragments]) as? [String:Any],
            let ios         = json?[OptimoveKeys.Notification.ios.rawValue] as? [String:Any],
            let deepLink =  ios[Bundle.main.bundleIdentifier?.setAsMongoKey() ?? "" ] as? String
        {
            return URL(string: deepLink)
        }
        return nil
    }
    
    func handleNotificationDelivered(_ userInfo: [AnyHashable : Any],
                                     completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        let task = UIApplication.shared.beginBackgroundTask(withName: "receive remote user notification")
        guard let campaignDetails = CampaignDetails.extractCampaignDetails(from: userInfo) else
        {
            buildNotificationContent(userInfo, nil, completionHandler)
            completionHandler(.newData)
            UIApplication.shared.endBackgroundTask(task)
            return
        }
        Optimove.sharedInstance.reportEvent(NotificationDelivered(campaignDetails: campaignDetails))
        Optimove.sharedInstance.dispatchQueuedEventsNow()
        DispatchQueue.main.asyncAfter(deadline: .now() + min(UIApplication.shared.backgroundTimeRemaining, 2.0))
        {
            UIApplication.shared.endBackgroundTask(task)
        }
        
        guard OptimoveUserDefaults.shared.isMbaasOptIn == true else
        {
            completionHandler(.newData)
            return
        }
        buildNotificationContent(userInfo, campaignDetails, completionHandler)
    }
}

extension OptimoveNotificationHandler: OptimoveNotificationHandling
{
    
    func didReceiveRemoteNotification(userInfo:[AnyHashable : Any],
                                      didComplete:@escaping (UIBackgroundFetchResult) -> Void)
    {
        Optimove.sharedInstance.startUrgentInitProcess { (success) in
            guard success else {
                OptiLogger.debug("Urgent initializtion failed")
                return
            }
            OptiLogger.debug("Urgent Initializtion success")
            
            OptiLogger.debug("Analyze notification")
            if userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true" {
                guard let commandString = (userInfo[OptimoveKeys.Notification.command.rawValue] as? String),
                    let command = OptimoveSdkCommand.init(rawValue: commandString) else {
                        OptiLogger.error("could not parse sdk command")
                        didComplete(.newData)
                        return
                }
                self.handleSdkCommand(command: command, completionHandler: didComplete)
            }
                
//            else if userInfo[Keys.Notification.isOptipush.rawValue] as? String == "true" {
//                self.handleNotificationDelivered(userInfo, completionHandler: didComplete)
//            } else {
//                didComplete(.noData)
//            }
        }
    }
    
    func didReceive(response:UNNotificationResponse,
                    withCompletionHandler completionHandler: @escaping ResultBlock)
    {
        Optimove.sharedInstance.startUrgentInitProcess { (success) in
            guard success else {
                OptiLogger.debug("Urgent initializtion failed")
                return
            }
            OptiLogger.debug("Urgent Initializtion success")
            
            
            self.reportNotification(response: response)
            if self.isNotificationOpened(response: response) {
                self.handleDeepLinkDelegation(response)
            }
            completionHandler()
        }
    }
}
// MARK: - Helper methods
extension OptimoveNotificationHandler
{
    private func isNotificationOpened(response:UNNotificationResponse) -> Bool
    {
        return response.actionIdentifier == UNNotificationDefaultActionIdentifier
    }
}

