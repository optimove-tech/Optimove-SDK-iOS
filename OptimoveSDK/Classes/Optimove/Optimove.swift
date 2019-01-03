//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications

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
        OptiLogger.debug(tag: "\(#function)","Start Configure Optimove SDK")
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
        let url  = OptimoveFileManager.getOptimoveSDKDirectory(isForSharedContainer: false).appendingPathComponent("Logs")
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
        OptimoveUserDefaults.shared.bundleId = Bundle.main.bundleIdentifier!
        OptiLogger.debug("stored user info in local storage: \ntoken:\(info.token)\nversion:\(info.version)\nend point:\(info.url)\nhas firebase:\(info.hasFirebase)\nuse Messaging: \(info.useFirebaseMessaging)")
    }
    
    private func configureLogger()
    {
//        OptiLogger.configure()
        let consoleStream = OptiConsoleLog()
        OptiLogger.add(stream: consoleStream)
    }
    
    private func setVisitorIdIfNeeded()
    {
        if OptimoveUserDefaults.shared.visitorID == nil {
            let uuid = UUID().uuidString
            let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
            let start = sanitizedUUID.startIndex
            let end = sanitizedUUID.index(start, offsetBy: 16)
            OptimoveUserDefaults.shared.initialVisitorId = String(sanitizedUUID[start..<end]).lowercased()
            OptimoveUserDefaults.shared.visitorID = OptimoveUserDefaults.shared.initialVisitorId
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

        if let clientApnsTOken = OptimoveUserDefaults.shared.apnsToken,RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.application(didRegisterForRemoteNotificationsWithDeviceToken: clientApnsTOken)
            OptimoveUserDefaults.shared.apnsToken = nil
        }
        for (_,delegate) in Optimove.swiftStateDelegates {
            delegate.observer?.optimove(self, didBecomeActiveWithMissingPermissions: deviceStateMonitor.getMissingPermissions())
        }
        for (_,delegate) in Optimove.objcStateDelegate {
            delegate.observer.optimove(self, didBecomeActiveWithMissingPermissions: deviceStateMonitor.getMissingPersmissions())
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
            OptiLogger.debug("user respond to non optimove notification")
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
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        } else {
            OptimoveUserDefaults.shared.apnsToken = deviceToken
        }
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
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.didReceiveFirebaseRegistrationToken(fcmToken: fcmToken)
        }
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
        let event = OptimoveEventDecoratorFactory.getEventDecorator(forEvent: originalEvent)
        
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
        
        if RunningFlagsIndication.isComponentRunning(.optiTrack), config.supportedOnOptitrack {
            OptiLogger.debug("report \(event.name) to optitrack")
            optiTrack.report(event: event, withConfigs: config)
        }  else {
            OptiLogger.debug("\(event.name) could not be reported to optitrack since it is not running")
        }

        if RunningFlagsIndication.isComponentRunning(.realtime) {
            if  config.supportedOnRealTime {
                OptiLogger.debug("report \(event.name) to realtime")
                realTime.report(event: event, withConfigs: config)
            } else {
                OptiLogger.debug("\(event.name) is not supported on realtime")
            }
        } else {
            OptiLogger.debug("\(event.name) could not be reported to realtime since it is not running")
            if event.name == OptimoveKeys.Configuration.setUserId.rawValue {
                OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
            } else if event.name == OptimoveKeys.Configuration.setEmail.rawValue {
                OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
            }
        }
    }

    @objc public func reportEvent(name:String,parameters:[String:Any]) {
        let customEvent = SimpleCustomEvent(name: name, parameters: parameters)
        self.reportEvent(customEvent)
    }

    @objc public func reportScreenVisit(screenPath: String, url: URL? = nil, category: String? = nil)
    {
        var screenPath = screenPath
        for prefix in ["https://www.", "http://www.", "https://", "http://"] {// Prefixes that shuold be removed. Order matters.
            if screenPath.hasPrefix(prefix) {
                screenPath.removeFirst(prefix.count)
                break
            }
        }
        self.reportScreenVisit(viewControllersIdentifiers: screenPath.components(separatedBy: "/"),
                          url: url,
                          category: category)
    }



    @objc public func reportScreenVisit(viewControllersIdentifiers: [String], url: URL? = nil, category: String? = nil)
    {
        OptiLogger.debug("user ask to report screen event")
        guard !viewControllersIdentifiers.isEmpty else {
            OptiLogger.error("trying to report screen visit with empty array")
            return
        }

        let pageTitle = generateOptimovePageTitle(fromViewControllersIdentifiers:viewControllersIdentifiers)
        let customUrl = generateOptimoveCustomUrl(fromProvided: url, andPageTitle: pageTitle)
        
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            optiTrack.reportScreenEvent(viewControllersIdentifiers: viewControllersIdentifiers, url: URL(string: customUrl)!,category: category)
        }
        if RunningFlagsIndication.isComponentRunning(.realtime) {
            realTime.reportScreenEvent(customURL: customUrl, pageTitle: pageTitle, category: category)
        }
    }

    private func generateOptimovePageTitle(fromViewControllersIdentifiers viewControllersIdentifiers: [String]) -> String
    {
        return viewControllersIdentifiers.joined(separator: "/")
    }

    private func generateOptimoveCustomUrl(fromProvided clientUrl:URL?, andPageTitle pageTitle:String) -> String
    {
        return (clientUrl != nil) ? clientUrl!.absoluteString : (Bundle.main.bundleIdentifier!).appending("/").appending(pageTitle).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
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
        guard isValid(userId: userID) else {
            OptiLogger.error("user id \(userID) is not valid")
            return
        }
        let userId = userID.trimmingCharacters(in: .whitespaces)


        //TODO: Move to Optipush
        if OptimoveUserDefaults.shared.customerID == nil {
            OptimoveUserDefaults.shared.isFirstConversion = true
        } else if userId != OptimoveUserDefaults.shared.customerID {
            OptiLogger.debug("user id changed from \(String(describing: OptimoveUserDefaults.shared.customerID)) to \(userId)" )
            if OptimoveUserDefaults.shared.isRegistrationSuccess == true {
                // send the first_conversion flag only if no previous registration has succeeded
                OptimoveUserDefaults.shared.isFirstConversion = false
            }
        } else {
            OptiLogger.warning("User Id \(userId) was already set in the Optimove SDK")
            return
        }
        OptimoveUserDefaults.shared.isRegistrationSuccess = false
        //

        let initialVisitorId = OptimoveUserDefaults.shared.initialVisitorId!
        let updatedVisitorId = getVisitorId(from:userId)
        OptimoveUserDefaults.shared.visitorID = updatedVisitorId
        OptimoveUserDefaults.shared.customerID = userId

        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            self.optiTrack.setUserId(userId)
        } else {
            OptiLogger.debug("set user id failed since optitrack not running")
            //Retry done inside optitrack module
        }

        let setUserIdEvent = SetUserId(originalVistorId: initialVisitorId,
                                       userId:userId,
                                       updateVisitorId:OptimoveUserDefaults.shared.visitorID!)
        reportEvent(setUserIdEvent)

        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.optiPush.performRegistration()
        } else {
            OptiLogger.debug("register use failed since optipush not running")
            // Retry handled inside optipush
        }
    }

    /// Produce a 16 characters string represents the visitor ID of the client
    ///
    /// - Parameter userId: The user ID which is the source
    /// - Returns: THe generated visitor ID
    private func getVisitorId(from userId: String) -> String
    {
        return SHA1.hexString(from: userId)?.replacingOccurrences(of: " ", with: "").prefix(16).description.lowercased() ?? ""
    }

    /// Send the user id and the user email
    ///
    /// - Parameters:
    ///   - email: The user email
    ///   - userId: THe user ID
    @objc public func registerUser(email:String, userId:String)
    {
        self.set(userID: userId)
        self.setUserEmail(email: email)
    }

    /// Call for the SDK to send the user email to its components
    ///
    /// - Parameter email: The user email
    @objc public func setUserEmail(email:String)
    {
        guard isValid(email: email) else {
            OptiLogger.debug("email is not valid")
            return
        }
        OptimoveUserDefaults.shared.userEmail = email
        reportEvent(SetEmailEvent(email: email))
    }



    /// Validate that the user id that provided by the client, feets with optimove conditions for valid user id
    ///
    /// - Parameter userId: the client user id
    /// - Returns: An indication of the validation of the provided user id
    private func isValid(userId:String) -> Bool
    {
        return !userId.isEmpty && !userId.contains("undefined") && !(userId == "null")
    }

    private func isValid(email:String) -> Bool
    {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
