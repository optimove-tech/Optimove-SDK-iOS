//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseDynamicLinks

protocol OptimoveNotificationHandling
{
    func didReceiveRemoteNotification(userInfo:[AnyHashable : Any],
                                      didComplete:@escaping (UIBackgroundFetchResult) -> Void)
    func didReceive(response:UNNotificationResponse,
                    withCompletionHandler completionHandler: @escaping (() -> Void))
}

@objc protocol OptimoveDeepLinkResponding
{
    @objc func register(deepLinkResponder responder: OptimoveDeepLinkResponder)
    @objc func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder)
}

protocol OptimoveEventReporting:class
{
    func reportEvent(_ event: OptimoveEvent)
    func dispatchQueuedEventsNow()
}

/**
 The entry point of Optimove SDK.
 Initialize and configure Optimove using Optimove.sharedOptimove.configure.
 */
@objc public final class Optimove: NSObject
{
    //MARK: - Attributes
    
    var optiPush: OptiPush!
    var optiTrack: OptiTrack!
    var realTime: RealTime!
    
    var eventWarehouse: OptimoveEventConfigsWarehouse?
    private let notificationHandler: OptimoveNotificationHandling
    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    
    static var swiftStateDelegates: [ObjectIdentifier: OptimoveSuccessStateListenerWrapper] = [:]
    
    static var objcStateDelegate: [ObjectIdentifier: OptimoveSuccessStateDelegateWrapper] = [:]
    
    private let stateDelegateQueue = DispatchQueue(label: "com.optimove.sdk_state_delegates")
    
    private var optimoveTestTopic: String {
        return "test_ios_\(Bundle.main.bundleIdentifier ?? "")"
    }
    
    //MARK: - Deep Link
    
    private var deepLinkResponders = [OptimoveDeepLinkResponder]()
    
    var deepLinkComponents: OptimoveDeepLinkComponents? {
        didSet {
            guard  let dlc = deepLinkComponents else {
                return
            }
            for responder in deepLinkResponders {
                responder.didReceive(deepLinkComponent: dlc)
            }
        }
    }
    
    
    // MARK: - API
    
    
    //MARK: - Initializers
    /// The shared instance of optimove singleton
    @objc public static let sharedInstance: Optimove =
        {
            let instance = Optimove()
            return instance
    }()
    
    private init(notificationListener: OptimoveNotificationHandling = OptimoveNotificationHandler(),
                 deviceStateMonitor: OptimoveDeviceStateMonitor = OptimoveDeviceStateMonitor()) {
        self.deviceStateMonitor = deviceStateMonitor
        self.notificationHandler = notificationListener
        super.init()
        self.setVisitorIdIfNeeded()
        
        self.optiPush = OptiPush(deviceStateMonitor: deviceStateMonitor)
        self.optiTrack = OptiTrack(deviceStateMonitor: deviceStateMonitor)
        self.realTime = RealTime(deviceStateMonitor: deviceStateMonitor)
    }
    /// The starting point of the Optimove SDK
    ///
    /// - Parameter info: Basic client information received on the onboarding process with Optimove
    @objc public func configure(for tenantInfo: OptimoveTenantInfo)
    {
        configureLogger()
        OptiLogger.debug("Start Configure Optimove SDK")
        storeTenantInfo(tenantInfo)
        startNormalInitProcess { (sucess) in
            guard sucess else {
                OptiLogger.debug("Normal initializtion failed")
                return
            }
            OptiLogger.debug("Normal Initializtion success")
        }
    }
    
    @objc public func getLogs() -> [Data]?
    {
        let url  = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent("Logs")
        guard let logsUrls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                          includingPropertiesForKeys: nil,
                                                                          options: .skipsHiddenFiles)
            else {return nil}
        var logs = [Data]()
        for logUrl in logsUrls
        {
            guard let log = try? Data.init(contentsOf: logUrl) else { continue }
            logs.append(log)
        }
        return logs
    }

    //MARK: - Private Methods
    
    /// stores the user information that was provided during configuration
    ///
    /// - Parameter info: user unique info
    private func storeTenantInfo(_ info: OptimoveTenantInfo)
    {
        OptimoveUserDefaults.shared.tenantToken = info.token
        OptimoveUserDefaults.shared.version = info.version
        OptimoveUserDefaults.shared.configurationEndPoint = info.url.last == "/" ? info.url : "\(info.url)/"
        OptimoveUserDefaults.shared.isClientHasFirebase = info.hasFirebase
        OptimoveUserDefaults.shared.isClientUseFirebaseMessaging = info.useFirebaseMessaging
        OptiLogger.debug("stored user info in local storage: \ntoken:\(info.token)\nversion:\(info.version)\nend point:\(info.url)\nhas firebase:\(info.hasFirebase)\nuse Messaging: \(info.useFirebaseMessaging)")
    }
    
    private func configureLogger()
    {
        OptiLogger.configure()
    }
    
    private func setVisitorIdIfNeeded()
    {
        if OptimoveUserDefaults.shared.visitorID == nil {
            let uuid = UUID().uuidString
            let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
            let start = sanitizedUUID.startIndex
            let end = sanitizedUUID.index(start, offsetBy: 16)
            OptimoveUserDefaults.shared.visitorID = String(sanitizedUUID[start..<end])
            OptimoveUserDefaults.shared.initialVisitorId = String(sanitizedUUID[start..<end])
            
        }
    }
}

// MARK: - Initialization API
extension Optimove
{
    func startNormalInitProcess(didSucceed: @escaping ResultBlockWithBool)
    {
        OptiLogger.debug("Start Optimove component initialization from remote")
        if RunningFlagsIndication.isSdkRunning  {
            OptiLogger.error("Skip normal initializtion since SDK already running")
            didSucceed(true)
            return
        }
        OptimoveSDKInitializer(deviceStateMonitor: deviceStateMonitor).initializeFromRemoteServer { success in
            guard success else {
                OptimoveSDKInitializer(deviceStateMonitor: self.deviceStateMonitor).initializeFromLocalConfigs { success in
                    didSucceed(success)
                }
                return
            }
            didSucceed(success)
        }
    }
    
    func startUrgentInitProcess(didSucceed: @escaping ResultBlockWithBool)
    {
        OptiLogger.debug("Start Optimove urgent initiazlition process")
        if RunningFlagsIndication.isSdkRunning  {
            OptiLogger.error("Skip urgent initializtion since SDK already running")
            didSucceed(true)
            return
        }
        OptimoveSDKInitializer(deviceStateMonitor: self.deviceStateMonitor).initializeFromLocalConfigs { success in
            didSucceed(success)
        }
    }
    
    func didFinishInitializationSuccessfully()
    {
        RunningFlagsIndication.isInitializerRunning = false
        RunningFlagsIndication.isSdkRunning = true
        for (_,delegate) in Optimove.swiftStateDelegates {
            delegate.observer?.optimove(self, didBecomeActiveWithMissingPermissions: deviceStateMonitor.getMissingPermissions())
        }
    }
}


// MARK: - SDK state observing
//TODO: expose to  @objc
extension Optimove
{
    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener)
    {
        if RunningFlagsIndication.isSdkRunning {
            listener.optimove(self, didBecomeActiveWithMissingPermissions: self.deviceStateMonitor.getMissingPermissions())
            return
        }
        stateDelegateQueue.async {
            Optimove.swiftStateDelegates[ObjectIdentifier(listener)] = OptimoveSuccessStateListenerWrapper(observer: listener)
        }
    }
    
    public func unregisterSuccessStateListener(_ delegate: OptimoveSuccessStateListener)
    {
        stateDelegateQueue.async {
            Optimove.swiftStateDelegates[ObjectIdentifier(delegate)] = nil
        }
    }
    
    @available(swift, obsoleted: 1.0)
    @objc public func registerSuccessStateDelegate(_ delegate:OptimoveSuccessStateDelegate)
    {
        if RunningFlagsIndication.isSdkRunning {
            delegate.optimove(self, didBecomeActiveWithMissingPermissions: self.deviceStateMonitor.getMissingPersmissions())
            return
        }
        stateDelegateQueue.async {
            Optimove.objcStateDelegate[ObjectIdentifier(delegate)] = OptimoveSuccessStateDelegateWrapper(observer: delegate)
        }
    }
    @available(swift, obsoleted: 1.0)
    @objc public func unregisterSuccessStateDelegate(_ delegate:OptimoveSuccessStateDelegate)
    {
        stateDelegateQueue.async {
            Optimove.objcStateDelegate[ObjectIdentifier(delegate)] = nil
        }
    }
}

// MARK: - Notification related API
extension Optimove
{
    /// Validate user notification permissions and sends the payload to the message handler
    ///
    /// - Parameters:
    ///   - userInfo: the data payload as sends by the the server
    ///   - completionHandler: an indication to the OS that the data is ready to be presented by the system as a notification
    @objc public func didReceiveRemoteNotification(userInfo: [AnyHashable: Any],
                                                   didComplete: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        OptiLogger.debug("Receive Remote Notification")
        guard userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true" else {
            return false
        }
        notificationHandler.didReceiveRemoteNotification(userInfo: userInfo,
                                                         didComplete: didComplete)
        return true
    }
    
    @objc public func willPresent(notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool
    {
        OptiLogger.debug("received notification in foreground mode")
        guard notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true"  else {
            OptiLogger.debug("notification should not be handled by optimove")
            return false
        }
        completionHandler([.alert, .sound,.badge])
        return true
    }
    
    /// Report user response to optimove notifications and send the client the related deep link to open
    ///
    /// - Parameters:
    ///   - response: The user response
    ///   - completionHandler: Indication about the process ending
    @objc public func didReceive(response:UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) -> Bool
    {
        guard response.notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true" else {
            return false
        }
        notificationHandler.didReceive(response: response,
                                       withCompletionHandler: completionHandler)
        return true
    }
}



// MARK: - OptiPush related API
extension Optimove
{
    /// Request to handle APNS <-> FCM regisration process
    ///
    /// - Parameter deviceToken: A token that was received in the appDelegate callback
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        optiPush.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    /// Request to subscribe to test campaign topics
    @objc public func startTestMode()
    {
        registerToOptipushTopic(optimoveTestTopic)
    }
    
    /// Request to unsubscribe from test campaign topics
    @objc public func stopTestMode()
    {
        unregisterFromOptipushTopic(optimoveTestTopic)
    }
    
    /// Request to register to topic
    ///
    /// - Parameter topic: The topic name
    @objc func registerToOptipushTopic(_ topic: String, didSucceed: ((Bool)->())? = nil)
    {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.subscribeToTopic(topic: topic,didSucceed: didSucceed)
        }
    }
    
    /// Request to unregister from topic
    ///
    /// - Parameter topic: The topic name
    @objc func unregisterFromOptipushTopic(_ topic: String,didSucceed: ((Bool)->())? = nil)
    {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.unsubscribeFromTopic(topic: topic,didSucceed: didSucceed)
        }
    }
    
    @objc public func optimove(didReceiveFirebaseRegistrationToken fcmToken: String )
    {
        optiPush.didReceiveFirebaseRegistrationToken(fcmToken: fcmToken)
    }
    
    func performRegistration()
    {
        if RunningFlagsIndication.isComponentRunning(.optiPush)
        {
            optiPush.performRegistration()
        }
    }
}

extension Optimove: OptimoveDeepLinkResponding
{
    @objc public func register(deepLinkResponder responder: OptimoveDeepLinkResponder)
    {
        if let dlc = self.deepLinkComponents {
            responder.didReceive(deepLinkComponent: dlc)
        } else {
            deepLinkResponders.append(responder)
        }
    }
    
    @objc public func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder)
    {
        if let index = self.deepLinkResponders.index(of: responder) {
            deepLinkResponders.remove(at: index)
        }
    }
}

extension Optimove:OptimoveEventReporting
{
    fileprivate func reportToOptiTrack(_ config: OptimoveEventConfig, _ event: OptimoveEventDecorator)
    {
        if config.supportedOnOptitrack {
            guard RunningFlagsIndication.isComponentRunning(.optiTrack) else {
                OptiLogger.debug("event \(event.name) not reported to optitrack since it is not running")
                return
            }
            OptiLogger.debug("report \(event.name) to optitrack")
            optiTrack.report(event: event, withConfigs: config)

        }
    }
    
    fileprivate func reportToRealtime(_ config: OptimoveEventConfig, _ event: OptimoveEvent, completionHandler:(()-> Void)? = nil)
    {
        if config.supportedOnRealTime {
            guard RunningFlagsIndication.isComponentRunning(.realtime) else {
                OptiLogger.debug("event \(event.name) not reported to realtime since it is not running")
                return
            }
            OptiLogger.debug("report \(event.name) to realtime")
            realTime.report(event: event, withConfigs: config)
        }
    }

    @objc public func dispatchQueuedEventsNow()
    {
        if RunningFlagsIndication.isSdkRunning {
            optiTrack.dispatchNow()
        }
    }
}

// MARK: - optiTrack related API
extension Optimove
{
    /// validate the permissions of the client to use optitrack component and if permit sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    @objc public func reportEvent(_ originalEvent: OptimoveEvent)
    {
        let event = OptimoveEventDecorator(event: originalEvent)

        guard let config = eventWarehouse?.getConfig(ofEvent: event) else {
            OptiLogger.error("configurations for event: \(event.name) are missing")
            return
        }
        event.processEventConfig(config)

        // Must pass the decorator in case some additional attributes become mandatory
        let eventValidationError = OptimoveEventValidator().validate(event: event, withConfig: config)
        guard eventValidationError == nil else {
            OptiLogger.error("report event \(event.name) is invalid with error \(eventValidationError!)")
            return
        }
        
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            reportToOptiTrack(config, event)
        }  else {
            OptiLogger.debug("\(event.name) could not be reported to optitrack since it is not running")
        }
        if RunningFlagsIndication.isComponentRunning(.realtime) {
            reportToRealtime(config, event)
        } else {
            OptiLogger.debug("\(event.name) could not be reported to realtime since it is not running")
        }
    }

    
    @objc public func reportScreenVisit(viewControllersIdentifiers: [String], url: URL? = nil, category: String? = nil)
    {
        guard !viewControllersIdentifiers.isEmpty else {
            OptiLogger.error("trying to report screen visit with empty array")
            return
        }
        optiTrack.setScreenEvent(viewControllersIdentifiers: viewControllersIdentifiers, url: url)
        
        var customUrl:String = ""
        let path = viewControllersIdentifiers.joined(separator: "/")
        let pageTitle = path
        if url != nil {
            customUrl = url!.absoluteString
        } else {
            customUrl = Bundle.main.bundleIdentifier!
            customUrl.append("/")
            customUrl.append(path)
        }
        
        reportEvent(PageVisitEvent(customURL: customUrl, pageTitle: pageTitle, category: category))
    }
}

// MARK: - set user id API
extension Optimove
{

    /// validate the permissions of the client to use optitrack component and if permit validate the userID content and sends:
    /// - conversion request to the DB
    /// - new customer registraion to the registration end point
    ///
    /// - Parameter userID: the client unique identifier
    @objc public func set(userID: String)
    {
        guard OptimoveEventValidator().validate(userId: userID) else {
            OptiLogger.error("user id \(userID) is not valid")
            return
        }
        let userId = userID.trimmingCharacters(in: .whitespaces)
        
        if OptimoveUserDefaults.shared.customerID == nil {
            OptimoveUserDefaults.shared.isFirstConversion = true
            OptimoveUserDefaults.shared.customerID = userId
            OptimoveUserDefaults.shared.isRegistrationSuccess = false
        } else if userId != OptimoveUserDefaults.shared.customerID {
            OptiLogger.debug("user id changed from \(String(describing: OptimoveUserDefaults.shared.customerID)) to \(userId)" )
            if OptimoveUserDefaults.shared.isRegistrationSuccess == true {
                OptimoveUserDefaults.shared.isFirstConversion = false
            }
            OptimoveUserDefaults.shared.customerID = userId
            OptimoveUserDefaults.shared.isRegistrationSuccess = false
        } else {
            return
        }
        
        let visitorId = OptimoveUserDefaults.shared.visitorID!
        let updatedVisitorId = SHA1.hexString(from: userId)?.replacingOccurrences(of: " ", with: "").prefix(16).description ?? ""
        let setUserIdEvent = SetUserId(originalVistorId: visitorId,userId:userId,updateVisitorId:updatedVisitorId)
        
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            self.optiTrack.setUserId(setUserIdEvent)
        } else {
            OptiLogger.debug("set user id failed since optitrack not running")
            //Retry done inside optitrack module
        }
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.optiPush.performRegistration()
        } else {
            OptiLogger.debug("register use failed since optipush not running")
            // Retry handled inside optipush
        }
        if RunningFlagsIndication.isComponentRunning(.realtime) {
            if let config = eventWarehouse?.getConfig(ofEvent:setUserIdEvent) {
                self.realTime.setUserId(setUserIdEvent, withConfig: config)
            } else {
                OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
                OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId = setUserIdEvent.originalVistorId
            }
        } else {
            OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
            OptimoveUserDefaults.shared.realtimeFailedOriginalVisitorId = setUserIdEvent.originalVistorId
            OptiLogger.debug("set user id failed since realtime not running")
            //Retry done inside realtime module
            
        }
        OptimoveUserDefaults.shared.visitorID = updatedVisitorId
        OptimoveUserDefaults.shared.customerID = userId
    }
}

//MARK: RealtimeAdditional events
extension Optimove
{
    @objc public func registerUser(email:String, userId:String)
    {
        self.set(userID: userId)
        self.setUserEmail(email: email)
    }
    @objc public func setUserEmail(email:String)
    {
        guard  isValidEmail(email: email) else {
            OptiLogger.debug("email is not valid")
            return
        }
        let event = SetEmailEvent(email: email)
        if let configs = eventWarehouse?.getConfig(ofEvent: event) {
            let decorator = OptimoveEventDecorator(event: event, config: configs)
            optiTrack.report(event: decorator, withConfigs: configs)
            realTime.setEmail(event, withConfig: configs)
        }
    }
    private func isValidEmail(email:String) -> Bool
    {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
