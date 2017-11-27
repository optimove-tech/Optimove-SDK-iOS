
//  Optipush.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications

final class Optipush:NSObject
{
    //MARK: - Variables
    var firebaseInteractor: FirebaseInteractor!
    var registrar: Registrar?
    
    var dynamicLinkResponders: [DynamicLinkResponder] = []
    var dynamicLinkComponents: DynamicLinkComponents?
    {
        didSet
        {
            guard  let dlc = dynamicLinkComponents else
            {
                return
            }
            for responder in dynamicLinkResponders {
                responder.didReceive(dynamicLink: dlc)
            }
        }
    }
    
    //MARK: - Constructor
    private override init()
    {
        super.init()
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    //MARK: Static Methods
    static func newIntsance(from json: [String: Any],
                            clientHasFirebase:Bool,
                            initializationDelegate: ComponentInitializationDelegate) -> Optipush?
    {
        LogManager.reportToConsole("Initialize OptiPush")
        guard let mobileConfig = json[Keys.Configuration.mobile.rawValue] as? [String: Any],
            let optipushConfig = mobileConfig[Keys.Configuration.optipushMetaData.rawValue] as? [String: Any],
            let optipushMetaData = Parser.parseOptipushMetaData(from: optipushConfig),
            let firebaseConfig = mobileConfig[Keys.Configuration.firebaseProjectKeys.rawValue] as? [String: Any],
            let firebaseMetaData = Parser.parseFirebaseKeys(from: firebaseConfig),
            let clientFirebaseConfig = mobileConfig[Keys.Configuration.clientServiceProjectKeys.rawValue] as? [String: Any],
            let clientFirebaseMetaData = Parser.parseFirebaseKeys(from: clientFirebaseConfig,isClientService: true),
            let isPermitted = json[Keys.Configuration.enableOptipush.rawValue] as? Bool
            else
        {
            LogManager.reportFailureToConsole("Failed to parse optipush metadata")
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .error)
            return nil
        }
        let state = isPermitted == true ? State.Component.active : .activeInternal
        let optipush = Optipush()
        
        optipush.firebaseInteractor = FirebaseInteractor(messageHandler: optipush)
        DispatchQueue.global(qos: .utility).async
            {
                optipush.registrar = Registrar(registrationEndPoint: optipushMetaData.registrationServiceRegistrationEndPoint,
                                               reportEndPoint: optipushMetaData.registrationServiceOtherEndPoint)
                optipush.registrar?.retryFailedOperationsIfExist()
                optipush.firebaseInteractor.setupFirebase(from: firebaseMetaData,
                                                 clientFirebaseMetaData: clientFirebaseMetaData,
                                                 clientHasFirebase:clientHasFirebase)
                optipush.enableNotifications()
                initializationDelegate.didFinishInitialization(of: .optiPush,withState: state)
        }
        LogManager.reportSuccessToConsole("OptiPush initialization succeed")
        return optipush
    }
    
    //MARK: - Internal methods
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        firebaseInteractor.handleRegistration(token:deviceToken)
    }
    
    func handleNotification(userInfo:[AnyHashable : Any],
                            completionHandler:(UIBackgroundFetchResult) -> Void)
    {
        guard userInfo[Keys.Notification.isOptipush.rawValue] as? String == "true"  else {return}
        let content = UNMutableNotificationContent()
        content.title = userInfo[Keys.Notification.title.rawValue] as? String ?? Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        content.body = userInfo[Keys.Notification.body.rawValue] as? String ?? ""
        
        injectDynamicLink(from:userInfo, to: content)
        let collapseId = userInfo[Keys.Notification.collapseId.rawValue] as? String ?? "OptipushDefaultCollapseID"
        if let campaignDetails = generateCampaignDetails(from: userInfo)
        {
            Optimove.sharedInstance.report(event: NotificationDelivered(campaignDetails: campaignDetails)) { (error) in }
            
            injectCampaignDetails(from: campaignDetails, to: content)
        }
        
        content.categoryIdentifier = NotificationCategoryIdentifiers.dismiss.rawValue
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: collapseId,
                                            content: content,
                                            trigger: trigger)
        configureUserNotifications()
        UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
        completionHandler(.newData)
    }
    
    func register(dynamicLinkResponder responder : DynamicLinkResponder)
    {
        if let dlc = self.dynamicLinkComponents
        {
            responder.didReceive(dynamicLink: dlc)
        }
        dynamicLinkResponders.append(responder)
    }
    
    func unregister(dynamicLinkResponder responder : DynamicLinkResponder)
    {
        if let index = dynamicLinkResponders.index(of: responder)
        {
            dynamicLinkResponders.remove(at: index)
        }
    }
    
    func subscribeToTestMode()
    {
        firebaseInteractor.subscribeTestMode()
    }
    
    func unsubscribeFromTestMode()
    {
        firebaseInteractor.unsubscribeTestMode()
    }
    
    //MARK: - Private Methods
    
    private func enableNotifications()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound])
        {[weak self] (granted, error) in
            self?.handlenNotificationAuthorizationResponse(granted: granted,error: error)
        }
    }
    
    private func injectDynamicLink(from userInfo: [AnyHashable : Any], to content: UNMutableNotificationContent)
    {
        if let dl           = userInfo[Keys.Notification.dynamicLinks.rawValue] as? String ,
            let data        = dl.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data, options:[.allowFragments]) as? [String:Any],
            let ios         = json?[Keys.Notification.ios.rawValue] as? [String:Any],
            let dynamicLink =  ios[Bundle.main.bundleIdentifier!.setAsMongoKey()] as? String
        {
            content.userInfo["dynamic_link"] = dynamicLink
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
    
    private func generateCampaignDetails(from userInfo: [AnyHashable : Any] ) -> CampaignDetails?
    {
        guard let campaignId   = (userInfo[Keys.Notification.campaignId.rawValue]   as? String),
        let actionSerial = (userInfo[Keys.Notification.actionSerial.rawValue]       as? String ),
        let templateId   = (userInfo[Keys.Notification.templateId.rawValue]         as? String ),
        let engagementId = (userInfo[Keys.Notification.engagementId.rawValue]       as? String ),
        let campaignType = (userInfo[Keys.Notification.campaignType.rawValue]       as? String )
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
}



extension Optipush: MessageHandleProtocol
{
    //MARK: - Protocol conformance
    func handleRegistrationTokenRefresh(token:String)
    {
        LogManager.reportToConsole("Enter to didRefreshRegistrationToken")
        LogManager.reportToConsole("fcmToken: \(token)")
        
        guard let oldFCMToken = UserInSession.shared.fcmToken
            else
        {
            LogManager.reportToConsole("Client receive a token for the first time")
            UserInSession.shared.fcmToken = token
            registrar?.register()
            return
        }
        
        if (token != oldFCMToken)
        {
            registrar?.unregister(didComplete:
                {
                    UserInSession.shared.fcmToken = token
                    self.registrar?.register()
            })
        }
    }
    fileprivate func reportNotification(response: UNNotificationResponse) {
       
        LogManager.reportToConsole("User react to notification")
        LogManager.reportToConsole("Action = \(response.actionIdentifier)")
        let notificationDetails = response.notification.request.content.userInfo
        
        if let campaignDetails = generateCampaignDetails(from: notificationDetails)
        {
            switch response.actionIdentifier
            {
            case UNNotificationDismissActionIdentifier:
                Optimove.sharedInstance.report(event:NotificationDismissed(campaignDetails: campaignDetails),
                                               completionHandler: { (error) in
                                                LogManager.reportSuccessToConsole("report notification dismiss")
                })
            case UNNotificationDefaultActionIdentifier:
                Optimove.sharedInstance.report(event: NotificationOpened(campaignDetails:campaignDetails),
                                               completionHandler: { (error) in
                                                LogManager.reportSuccessToConsole("report notification opened")
                })
            default: break
            }
        }
    }
    
    fileprivate func extractDynamicLink(from response: UNNotificationResponse) {
        if let dynamicLink =  response.notification.request.content.userInfo["dynamic_link"] as? String
        {
            let shortUrl = URL(string: dynamicLink )
            firebaseInteractor.getDynamicLinks(from: shortUrl, completionHandler: { (components) in
                self.dynamicLinkComponents = components
            })
        }
    }
    
    func handleUserNotificationResponse(response:UNNotificationResponse)
        
    {
        reportNotification(response: response)
        extractDynamicLink(from: response)
    }
    
    private func handlenNotificationAuthorizationResponse( granted: Bool, error: Error?)
    {
        switch granted
        {
        case true:
            LogManager.reportSuccessToConsole("Notification authorized by user")
            guard let isOptIn = UserInSession.shared.isOptIn
                else { //Opt in on first launch
                    UserInSession.shared.isOptIn = true
                    return
            }
            if !isOptIn
            {
                self.registrar?.optIn()
            }
        case false:
            LogManager.reportFailureToConsole("Notification unauthorized by user")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            guard let isOptIn = UserInSession.shared.isOptIn else
            {
                guard UserInSession.shared.fcmToken != nil
                    else
                {
                    UserInSession.shared.isOptIn = false
                    return
                }
                if UserInSession.shared.isRegistrationSuccess
                {
                    UserInSession.shared.isOptIn = false
                    self.registrar?.optOut()
                }
                return
            }
            if isOptIn
            {
                if !(UserInSession.shared.hasRegisterJsonFile ?? false)
                {
                    self.registrar?.optOut()
                }
            }
        }
    }
    
    
    private func configureUserNotifications()
    {
        let category = UNNotificationCategory(identifier: NotificationCategoryIdentifiers.dismiss.rawValue,
                                              actions: [],
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
