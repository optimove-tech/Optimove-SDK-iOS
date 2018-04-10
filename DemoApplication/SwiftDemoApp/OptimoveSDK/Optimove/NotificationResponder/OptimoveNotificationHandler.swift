//
//  NotificationResponder.swift
//  DevelopSDK
//
//  Created by Elkana Orbach on 23/11/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

enum NotificationState
{
    case opened
    case delivered
    case dismissed
}
class OptimoveNotificationHandler: NSObject
{
    public static let NotificationDispatchSemaphore = DispatchSemaphore(value: 1)
    
    //MARK: - Initializer
    override init()
    {
        super.init()
        if UserInSession.shared.useOptipush != nil && UserInSession.shared.useOptipush! {
            setDelegate()
        }
    }
    
    //MARK: - API
    fileprivate func buildNotificationContent(_ userInfo: [AnyHashable : Any], _ campaignDetails: CampaignDetails?, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = userInfo[Keys.Notification.title.rawValue] as? String ?? Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        content.body = userInfo[Keys.Notification.body.rawValue] as? String ?? ""
        content.categoryIdentifier = NotificationCategoryIdentifiers.dismiss
        insertCampaignDetails(from: campaignDetails, to: content)
        
        insertLongDeepLinkUrl(from:userInfo, to: content)
        {
            let collapseId = (Bundle.main.bundleIdentifier ?? "") + "_" + (userInfo[Keys.Notification.collapseId.rawValue] as? String ?? "OptipushDefaultCollapseID")
            Optimove.sharedInstance.logger.debug("Collapse id: \(collapseId)")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.6, repeats: false)
            let request = UNNotificationRequest(identifier: collapseId,
                                                content: content,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
            completionHandler(.newData)
        }
    }
    
    func setDelegate()
    {
        if UNUserNotificationCenter.current().delegate == nil {
            UNUserNotificationCenter.current().delegate = self
            configureUserNotificationsDismissCategory()
        }
    }
    func handleNotification(userInfo:[AnyHashable : Any],
                            completionHandler:@escaping (UIBackgroundFetchResult) -> Void)
    {
        guard userInfo[Keys.Notification.isOptipush.rawValue] as? String == "true"  else
        {
            completionHandler(.noData)
            return
        }
        var campaignDetails:CampaignDetails? = nil
        if let pushCampaignDetails = CampaignDetails.extractCampaignDetails(from: userInfo) {
            campaignDetails = pushCampaignDetails
        reportNotification(.delivered,campaignDetails:pushCampaignDetails)
        }
        
        guard UserInSession.shared.isOptIn == true else
        {
            completionHandler(.noData)
            return
        }
        
        buildNotificationContent(userInfo, campaignDetails, completionHandler)
        
    }

    //MARK: - Private Methods
    
    private func reportNotification(response: UNNotificationResponse)
    {
        Optimove.sharedInstance.logger.debug("User react to notification")
        Optimove.sharedInstance.logger.debug("Action = \(response.actionIdentifier)")
        
        let notificationDetails = response.notification.request.content.userInfo
        
        if let campaignDetails = CampaignDetails.extractCampaignDetails(from: notificationDetails)
        {
            switch response.actionIdentifier
            {
            case UNNotificationDismissActionIdentifier:
                reportNotification(.dismissed, campaignDetails: campaignDetails)
            case UNNotificationDefaultActionIdentifier:
                reportNotification(.opened,campaignDetails: campaignDetails)
            default: break
            }
        }
    }

    private func reportNotification(_ type: NotificationState, campaignDetails: CampaignDetails)
    {
        let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        let event: NotificationEvent
        switch type
        {
        case .dismissed:
            Optimove.sharedInstance.logger.debug("before report notification dismissed: \(campaignDetails.campaignId)")
            event = NotificationDismissed(campaignDetails: campaignDetails)
        case .opened:
            Optimove.sharedInstance.logger.debug("before report notification opened: \(campaignDetails.campaignId)")
            event = NotificationOpened(campaignDetails: campaignDetails)
        case .delivered:
            Optimove.sharedInstance.logger.debug("before report notification delivered: \(campaignDetails.campaignId)")
            event = NotificationDelivered(campaignDetails: campaignDetails)
        }
        
        let saveResult = self.save(event)
        if UIApplication.shared.backgroundTimeRemaining < 6 || type == .opened
        {
            // piwik timeout is 5 sec. not enough time. don't even try.
            UIApplication.shared.endBackgroundTask(taskId)
            return
        }
        
        Optimove.sharedInstance.criticalReportSync(event: event)
        {
            success in
            OptimoveNotificationHandler.NotificationDispatchSemaphore.signal()
            guard success else
            {
                UIApplication.shared.endBackgroundTask(taskId)
                return
            }
            Optimove.sharedInstance.logger.debug("report notification \(type) with campiagn id: \(campaignDetails.campaignId)")
            Optimove.sharedInstance.clearStoredNotificationEvent(at: saveResult.index, withOldSize: saveResult.newSize)
            UIApplication.shared.endBackgroundTask(taskId)
        }
    }
    
    private func save(_ event:NotificationEvent) -> (index:Int,newSize:Int)
    {
        var startIndex  = 0
        var newCount = 0
        Optimove.sharedInstance.notificationEventQueue.sync
            {
                var arr = UserInSession.shared.backupNotificationEvents
                startIndex = arr.count
                arr.append(event.backupString())
                newCount = arr.count
                UserInSession.shared.backupNotificationEvents = arr
        }
        return (startIndex,newCount)
    }
    
    private func insertLongDeepLinkUrl(from userInfo: [AnyHashable : Any], to content: UNMutableNotificationContent, withCompletionHandler completionHandler: @escaping ResultBlock)
    {
        if let url = extractDeepLink(from: userInfo)
        {
            DynamicLinks.dynamicLinks()?.handleUniversalLink(url)
            { (longUrl, error) in
                if error != nil
                {
                    Optimove.sharedInstance.logger.severe("Deep link could not be extracted. error: \(error!.localizedDescription)")
                }
                else
                {
                    content.userInfo[Keys.Notification.dynamikLink.rawValue] = longUrl?.url?.absoluteString
                }
                completionHandler()
            }
        }
        else
        {
            completionHandler()
        }
    }
    
    private func insertCampaignDetails(from campaignDetails: CampaignDetails?,  to content: UNMutableNotificationContent)
    {
        guard let campaignDetails = campaignDetails else {return}
        content.userInfo[Keys.Notification.campaignId.rawValue]     = campaignDetails.campaignId
        content.userInfo[Keys.Notification.actionSerial.rawValue]   = campaignDetails.actionSerial
        content.userInfo[Keys.Notification.templateId.rawValue]     = campaignDetails.templateId
        content.userInfo[Keys.Notification.engagementId.rawValue]   = campaignDetails.engagementId
        content.userInfo[Keys.Notification.campaignType.rawValue]   = campaignDetails.campaignType
    }
    
    private func handleDeepLinkDelegation(_ response: UNNotificationResponse) {
        if let dynamicLink =  response.notification.request.content.userInfo[Keys.Notification.dynamikLink.rawValue] as? String
        {
            if let absoluteUrl = URL(string: dynamicLink)
            {
                Optimove.sharedInstance.logger.debug("store dynamic link of message")
                if let screenName = absoluteUrl.pathComponents.last {
                    let query = absoluteUrl.queryParameters
                    Optimove.sharedInstance.deepLinkComponents = OptimoveDeepLinkComponents(screenName: screenName, query: query)
                }
            }
        }
    }
    
    private func isNotificationOpened(response:UNNotificationResponse) -> Bool
    {
        return response.actionIdentifier == UNNotificationDefaultActionIdentifier
    }
    
    private func handleUserNotificationResponse(response:UNNotificationResponse)
    {
        reportNotification(response: response)
        
        if isNotificationOpened(response: response)
        {
            handleDeepLinkDelegation(response)
        }
    }
    
    private func configureUserNotificationsDismissCategory()
    {
        let category = UNNotificationCategory(identifier: NotificationCategoryIdentifiers.dismiss,
                                              actions: [],
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func extractDeepLink(from userInfo:  [AnyHashable : Any]) -> URL?
    {
        if let dl           = userInfo[Keys.Notification.dynamicLinks.rawValue] as? String ,
            let data        = dl.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data, options:[.allowFragments]) as? [String:Any],
            let ios         = json?[Keys.Notification.ios.rawValue] as? [String:Any],
            let deepLink =  ios[Bundle.main.bundleIdentifier?.setAsMongoKey() ?? "" ] as? String
        {
            return URL(string: deepLink)
        }
        return nil
    }
}

//MARK: - UNUserNotificationCenterDelegate implementation

extension OptimoveNotificationHandler: UNUserNotificationCenterDelegate
{
    fileprivate func initializeOptimoveComponentsFromLocalStorage()
    {
        Optimove.sharedInstance.logger.debug("start local init of optimove")
        OptimoveComponentsInitializer.init(isClientFirebaseExist: UserInSession.shared.userHasFirebase).startFromLocalConfigs()
        Optimove.sharedInstance.logger.debug("finish local init of optimove")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        initializeOptimoveComponentsFromLocalStorage()
        handleUserNotificationResponse(response: response)
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert,.sound])
    }
}
