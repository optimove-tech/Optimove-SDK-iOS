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

class OptimoveNotificationHandler: NSObject
{
   override init()
    {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        configureUserNotifications()
    }
    
    func buildPushNotification(userInfo:[AnyHashable : Any],
                            completionHandler:@escaping (UIBackgroundFetchResult) -> Void)
    {
        guard userInfo[Keys.Notification.isOptipush.rawValue] as? String == "true"  else
        {
            completionHandler(.noData)
            return
        }
        
        let content = UNMutableNotificationContent()
        if let campaignDetails = extractCampaignDetails(from: userInfo)
        {
            reportNotification(.delivered,campaignDetails:campaignDetails)
            
            injectCampaignDetails(from: campaignDetails, to: content)
        }
        guard UserInSession.shared.isOptIn == true else
        {
            completionHandler(.noData)
            return
        }
        
        content.title = userInfo[Keys.Notification.title.rawValue] as? String ?? Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        content.body = userInfo[Keys.Notification.body.rawValue] as? String ?? ""
        content.categoryIdentifier = NotificationCategoryIdentifiers.dismiss
//        content.threadIdentifier = Bundle.main.bundleIdentifier!
        
        injectDeepLink(from:userInfo, to: content)
        {
            let collapseId = (Bundle.main.bundleIdentifier ?? "") + "_" + (userInfo[Keys.Notification.collapseId.rawValue] as? String ?? "OptipushDefaultCollapseID")
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.6, repeats: false)
            let request = UNNotificationRequest(identifier: collapseId,
                                                content: content,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
            completionHandler(.newData)
        }
    }
    

    enum NotificationState
    {
        case opened
        case delivered
        case dismissed
    }
    
    private func reportNotification(_ type: NotificationState, campaignDetails: CampaignDetails)
    {
        let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        let event: NotificationEvent
        switch type
        {
        case .dismissed:
            event = NotificationDismissed(campaignDetails: campaignDetails)
        case .opened:
            event = NotificationOpened(campaignDetails: campaignDetails)
        case .delivered:
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
            guard success else
            {
                UIApplication.shared.endBackgroundTask(taskId)
                return
            }
            Optimove.sharedInstance.logger.debug("report notification \(type)")
            Optimove.sharedInstance.clearStoredNotificationEvent(at: saveResult.index, withOldSize: saveResult.newSize)
            UIApplication.shared.endBackgroundTask(taskId)
        }
    }
    
    func save(_ event:NotificationEvent) -> (index:Int,newSize:Int)
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
    
    private func injectDeepLink(from userInfo: [AnyHashable : Any], to content: UNMutableNotificationContent, withCompletionHandler completionHandler: @escaping ResultBlock)
    {
        if let dl           = userInfo[Keys.Notification.dynamicLinks.rawValue] as? String ,
            let data        = dl.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data, options:[.allowFragments]) as? [String:Any],
            let ios         = json?[Keys.Notification.ios.rawValue] as? [String:Any],
            let deepLink =  ios[Bundle.main.bundleIdentifier?.setAsMongoKey() ?? "" ] as? String
        {
            if let url = URL(string:deepLink)
            {
                DynamicLinks.dynamicLinks()?.handleUniversalLink(url)
                { (deepLink, error) in
                    if error != nil
                    {
                        Optimove.sharedInstance.logger.severe("Deep link could not be extracted. error: \(error!)")
                    }
                    else
                    {
                        content.userInfo["dynamic_link"] = deepLink?.url?.absoluteString
                    }
                    completionHandler()
                }
            }
        }
        else
        {
            completionHandler()
        }
    }
    
    private func injectCampaignDetails(from campaignDetails: CampaignDetails,  to content: UNMutableNotificationContent)
    {
        content.userInfo[Keys.Notification.campaignId.rawValue]     = campaignDetails.campaignId
        content.userInfo[Keys.Notification.actionSerial.rawValue]   = campaignDetails.actionSerial
        content.userInfo[Keys.Notification.templateId.rawValue]     = campaignDetails.templateId
        content.userInfo[Keys.Notification.engagementId.rawValue]   = campaignDetails.engagementId
        content.userInfo[Keys.Notification.campaignType.rawValue]   = campaignDetails.campaignType
    }
    
    private func extractCampaignDetails(from userInfo: [AnyHashable : Any] ) -> CampaignDetails?
    {
        guard let campaignId   = (userInfo[Keys.Notification.campaignId.rawValue]   as? String),
            let actionSerial = (userInfo[Keys.Notification.actionSerial.rawValue]   as? String),
            let templateId   = (userInfo[Keys.Notification.templateId.rawValue]     as? String),
            let engagementId = (userInfo[Keys.Notification.engagementId.rawValue]   as? String),
            let campaignType = (userInfo[Keys.Notification.campaignType.rawValue]   as? String)
            else
        {
            return nil
        }
        
        return CampaignDetails(campaignId: campaignId,
                               actionSerial: actionSerial,
                               templateId: templateId,
                               engagementId: engagementId,
                               campaignType: campaignType)
    }
    
    func handleUserNotificationResponse(response:UNNotificationResponse)
    {
        reportNotification(response: response)
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {return}
        if let dynamicLink =  response.notification.request.content.userInfo["dynamic_link"] as? String
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
    
    private func reportNotification(response: UNNotificationResponse)
    {
        Optimove.sharedInstance.logger.debug("User react to notification")
        Optimove.sharedInstance.logger.debug("Action = \(response.actionIdentifier)")
        
        let notificationDetails = response.notification.request.content.userInfo
        
        if let campaignDetails = extractCampaignDetails(from: notificationDetails)
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
    
    private func configureUserNotifications()
    {
        let category = UNNotificationCategory(identifier: NotificationCategoryIdentifiers.dismiss,
                                              actions: [],
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension OptimoveNotificationHandler: UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
            Optimove.sharedInstance.logger.debug("start local init of optimove")
            OptimoveComponentsInitializer.init(isClientFirebaseExist: UserInSession.shared.userHasFirebase).startFromLocalConfigs()
            Optimove.sharedInstance.logger.debug("finish local init of optimove")
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
