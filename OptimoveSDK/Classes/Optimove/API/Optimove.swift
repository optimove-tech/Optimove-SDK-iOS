//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import UserNotifications

protocol OptimoveEventReporting: class {
    func reportEvent(_ event: OptimoveEvent)
    func dispatchQueuedEventsNow()
}

/**
 The entry point of Optimove SDK.
 Initialize and configure Optimove using Optimove.sharedOptimove.configure.
 */
@objc public final class Optimove: NSObject {
    // MARK: - Attributes
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

    // MARK: - Deep Link

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

    // MARK: - Initializers
    /// The shared instance of optimove singleton
    @objc public static let shared: Optimove = {
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
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        shared.configureLogger()
        OptiLoggerMessages.logStartConfigureOptimoveSDK()
        shared.storeTenantInfo(tenantInfo)
        shared.startNormalInitProcess { (sucess) in
            guard sucess else {
                OptiLoggerMessages.logNormalInitFailed()
                return
            }
            OptiLoggerMessages.logNormalInitSuccess()
        }
    }

    

    // MARK: - Private Methods

    /// stores the user information that was provided during configuration
    ///
    /// - Parameter info: user unique info
    private func storeTenantInfo(_ info: OptimoveTenantInfo) {
        OptimoveUserDefaults.shared.tenantToken = info.tenantToken
        OptimoveUserDefaults.shared.version = info.configName
        OptimoveUserDefaults.shared.configurationEndPoint = info.url.last == "/" ? info.url : "\(info.url)/"

        OptimoveUserDefaults.shared.bundleId = Bundle.main.bundleIdentifier!
        OptiLoggerMessages.logStoreUserInfo(tenantToken: info.tenantToken, tenantVersion: info.configName, tenantUrl: info.url)
       
    }

    private func configureLogger() {
        let consoleStream = OptiLoggerConsoleStream()
        OptiLoggerStreamsContainer.add(stream: consoleStream)
        if EnvVars.isClientStgEnv {
            OptiLoggerStreamsContainer.add(stream: MobileLogServiceLoggerStream(tenantId: TenantID ?? -1))
        }
    }

    private func setVisitorIdIfNeeded() {
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
extension Optimove {
    func startNormalInitProcess(didSucceed: @escaping ResultBlockWithBool) {
        OptiLoggerMessages.logStartInitFromRemote()
        if RunningFlagsIndication.isSdkRunning {
            OptiLoggerMessages.logSkipNormalInitSinceRunning()
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

    func startUrgentInitProcess(didSucceed: @escaping ResultBlockWithBool) {
        OptiLoggerMessages.logStartUrgentInitProcess()
        if RunningFlagsIndication.isSdkRunning {
            OptiLoggerMessages.logSkipUrgentInitSinceRunning()
            didSucceed(true)
            return
        }
        OptimoveSDKInitializer(deviceStateMonitor: self.deviceStateMonitor).initializeFromLocalConfigs { success in
            didSucceed(success)
        }
    }

    func didFinishInitializationSuccessfully() {
        RunningFlagsIndication.isInitializerRunning = false
        RunningFlagsIndication.isSdkRunning = true

        if let clientApnsTOken = OptimoveUserDefaults.shared.apnsToken, RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.application(didRegisterForRemoteNotificationsWithDeviceToken: clientApnsTOken)
            OptimoveUserDefaults.shared.apnsToken = nil
        }
        for (_, delegate) in Optimove.swiftStateDelegates {
            delegate.observer?.optimove(self, didBecomeActiveWithMissingPermissions: deviceStateMonitor.getMissingPermissions())
        }
        for (_, delegate) in Optimove.objcStateDelegate {
            delegate.observer.optimove(self, didBecomeActiveWithMissingPermissions: deviceStateMonitor.getMissingPersmissions())
        }
    }
}

// MARK: - SDK state observing
//TODO: expose to  @objc
extension Optimove {
    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        if RunningFlagsIndication.isSdkRunning {
            listener.optimove(self, didBecomeActiveWithMissingPermissions: self.deviceStateMonitor.getMissingPermissions())
            return
        }
        stateDelegateQueue.async {
            Optimove.swiftStateDelegates[ObjectIdentifier(listener)] = OptimoveSuccessStateListenerWrapper(observer: listener)
        }
    }

    public func unregisterSuccessStateListener(_ delegate: OptimoveSuccessStateListener) {
        stateDelegateQueue.async {
            Optimove.swiftStateDelegates[ObjectIdentifier(delegate)] = nil
        }
    }

    @available(swift, obsoleted: 1.0)
    @objc public func registerSuccessStateDelegate(_ delegate: OptimoveSuccessStateDelegate) {
        if RunningFlagsIndication.isSdkRunning {
            delegate.optimove(self, didBecomeActiveWithMissingPermissions: self.deviceStateMonitor.getMissingPersmissions())
            return
        }
        stateDelegateQueue.async {
            Optimove.objcStateDelegate[ObjectIdentifier(delegate)] = OptimoveSuccessStateDelegateWrapper(observer: delegate)
        }
    }
    @available(swift, obsoleted: 1.0)
    @objc public func unregisterSuccessStateDelegate(_ delegate: OptimoveSuccessStateDelegate) {
        stateDelegateQueue.async {
            Optimove.objcStateDelegate[ObjectIdentifier(delegate)] = nil
        }
    }
}

// MARK: - Notification related API
extension Optimove {
    /// Validate user notification permissions and sends the payload to the message handler
    ///
    /// - Parameters:
    ///   - userInfo: the data payload as sends by the the server
    ///   - completionHandler: an indication to the OS that the data is ready to be presented by the system as a notification
    @objc public func didReceiveRemoteNotification(userInfo: [AnyHashable: Any],
                                                   didComplete: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        OptiLoggerMessages.logReceiveRemoteNotification()
        guard userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true" else {
            return false
        }
        notificationHandler.didReceiveRemoteNotification(userInfo: userInfo,
                                                         didComplete: didComplete)
        return true
    }

    @objc public func willPresent(notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
        OptiLoggerMessages.logReceiveNotificationInForeground()
        guard notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true"  else {
            OptiLoggerMessages.logNotificationShouldNotHandleByOptimove()
            return false
        }
        completionHandler([.alert, .sound, .badge])
        return true
    }

    /// Report user response to optimove notifications and send the client the related deep link to open
    ///
    /// - Parameters:
    ///   - response: The user response
    ///   - completionHandler: Indication about the process ending
    @objc public func didReceive(response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        guard response.notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true" else {
            OptiLoggerMessages.logNotificationResponse()
            return false
        }
        notificationHandler.didReceive(response: response,
                                       withCompletionHandler: completionHandler)
        return true
    }
}

// MARK: - OptiPush related API
extension Optimove {
    /// Request to handle APNS <-> FCM regisration process
    ///
    /// - Parameter deviceToken: A token that was received in the appDelegate callback
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        } else {
            OptimoveUserDefaults.shared.apnsToken = deviceToken
        }
    }

    /// Request to subscribe to test campaign topics
    @objc public func startTestMode() {
        registerToOptipushTopic(optimoveTestTopic)
    }

    /// Request to unsubscribe from test campaign topics
    @objc public func stopTestMode() {
        unregisterFromOptipushTopic(optimoveTestTopic)
    }

    /// Request to register to topic
    ///
    /// - Parameter topic: The topic name
    func registerToOptipushTopic(_ topic: String, didSucceed: ((Bool)->Void)? = nil) {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.subscribeToTopic(topic: topic, didSucceed: didSucceed)
        }
    }

    /// Request to unregister from topic
    ///
    /// - Parameter topic: The topic name
     func unregisterFromOptipushTopic(_ topic: String, didSucceed: ((Bool)->Void)? = nil) {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.unsubscribeFromTopic(topic: topic, didSucceed: didSucceed)
        }
    }

    func performRegistration() {
        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            optiPush.performRegistration()
        }
    }
}

extension Optimove: OptimoveDeepLinkResponding {
    @objc public func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        if let dlc = self.deepLinkComponents {
            responder.didReceive(deepLinkComponent: dlc)
        } else {
            deepLinkResponders.append(responder)
        }
    }

    @objc public func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        if let index = self.deepLinkResponders.index(of: responder) {
            deepLinkResponders.remove(at: index)
        }
    }
}

extension Optimove: OptimoveEventReporting {
    func dispatchQueuedEventsNow() {
        if RunningFlagsIndication.isSdkRunning {
            optiTrack.dispatchNow()
        }
    }
}

// MARK: - optiTrack related API
extension Optimove {
    /// validate the permissions of the client to use optitrack component and if permit sends the report to the apropriate handler
    ///
    /// - Parameters:
    ///   - event: optimove event object
    @objc public func reportEvent(_ event: OptimoveEvent) {
        let eventDecor = OptimoveEventDecoratorFactory.getEventDecorator(forEvent: event)

        guard let config = eventWarehouse?.getConfig(ofEvent: eventDecor) else {
            OptiLoggerMessages.logConfigurationForEventMissing(eventName: eventDecor.name)
            return
        }
        eventDecor.processEventConfig(config)

        // Must pass the decorator in case some additional attributes become mandatory
        let eventValidationError = OptimoveEventValidator().validate(event: eventDecor, withConfig: config)
        guard eventValidationError == nil else {
            OptiLoggerMessages.logReportEventFailed(eventName: eventDecor.name, eventValidationError: eventValidationError!.localizedDescription)
            return
        }

        if RunningFlagsIndication.isComponentRunning(.optiTrack), config.supportedOnOptitrack {
            OptiLoggerMessages.logOptitrackReport(event: eventDecor.name)
            optiTrack.report(event: eventDecor, withConfigs: config)
        } else {
            OptiLoggerMessages.logOptiTrackNotRunning(eventName: eventDecor.name)
        }

        if RunningFlagsIndication.isComponentRunning(.realtime) {
            if  config.supportedOnRealTime {
                OptiLoggerMessages.logRealtimeReportEvent(eventName: eventDecor.name)
                realTime.report(eventDecor: eventDecor, withConfigs: config)
            } else {
                OptiLoggerMessages.logEventNotsupportedOnRealtime(eventName: eventDecor.name)
            }
        } else {
            OptiLoggerMessages.logRealtimeNotrunning(eventName: eventDecor.name)
            if eventDecor.name == OptimoveKeys.Configuration.setUserId.rawValue {
                OptimoveUserDefaults.shared.realtimeSetUserIdFailed = true
            } else if eventDecor.name == OptimoveKeys.Configuration.setEmail.rawValue {
                OptimoveUserDefaults.shared.realtimeSetEmailFailed = true
            }
        }
    }

    @objc public func reportEvent(name: String, parameters: [String: Any]) {
        let customEvent = SimpleCustomEvent(name: name, parameters: parameters)
        self.reportEvent(customEvent)
    }

}

// MARK: - set user id API
extension Optimove {

    /// validate the permissions of the client to use optitrack component and if permit validate the sdkId content and sends:
    /// - conversion request to the DB
    /// - new customer registraion to the registration end point
    ///
    /// - Parameter sdkId: the client unique identifier
    @objc public func setUserId(_ sdkId: String) {
        let userId = sdkId.trimmingCharacters(in: .whitespaces)
        guard isValid(userId: userId) else {
            OptiLoggerMessages.logUserIdNotValid(userID: userId)
            return
        }

        //TODO: Move to Optipush
        if OptimoveUserDefaults.shared.customerID == nil {
            OptimoveUserDefaults.shared.isFirstConversion = true
        } else if userId != OptimoveUserDefaults.shared.customerID {
            OptiLoggerStreamsContainer.log(level:.debug,
                                           fileName: #file,
                                           methodName: #function,
                                           logModule: "Optimove",
                                           "user id changed from \(String(describing: OptimoveUserDefaults.shared.customerID)) to \(userId)" )
            if OptimoveUserDefaults.shared.isRegistrationSuccess == true {
                // send the first_conversion flag only if no previous registration has succeeded
                OptimoveUserDefaults.shared.isFirstConversion = false
            }
        } else {
            OptiLoggerMessages.logUserIdNotNew(userId: userId)
            return
        }
        OptimoveUserDefaults.shared.isRegistrationSuccess = false
        //

        let initialVisitorId = OptimoveUserDefaults.shared.initialVisitorId!
        let updatedVisitorId = getVisitorId(from: userId)
        OptimoveUserDefaults.shared.visitorID = updatedVisitorId
        OptimoveUserDefaults.shared.customerID = userId

        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            self.optiTrack.setUserId(userId)
        } else {
            OptiLoggerMessages.logOptitrackNotRunningForSetUserId()
            //Retry done inside optitrack module
        }

        let setUserIdEvent = SetUserId(originalVistorId: initialVisitorId,
                                       userId: userId,
                                       updateVisitorId: OptimoveUserDefaults.shared.visitorID!)
        reportEvent(setUserIdEvent)

        if RunningFlagsIndication.isComponentRunning(.optiPush) {
            self.optiPush.performRegistration()
        } else {
            OptiLoggerMessages.logOptipushNOtRunningForRegistration()
            // Retry handled inside optipush
        }
    }

    /// Produce a 16 characters string represents the visitor ID of the client
    ///
    /// - Parameter userId: The user ID which is the source
    /// - Returns: THe generated visitor ID
    private func getVisitorId(from userId: String) -> String {
        return SHA1.hexString(from: userId)?.replacingOccurrences(of: " ", with: "").prefix(16).description.lowercased() ?? ""
    }

    /// Send the user id and the user email
    ///
    /// - Parameters:
    ///   - email: The user email
    ///   - userId: THe user ID
    @objc public func registerUser(email: String, sdkId: String) {
        self.setUserId(sdkId)
        self.setUserEmail(email: email)
    }

    /// Call for the SDK to send the user email to its components
    ///
    /// - Parameter email: The user email
    @objc public func setUserEmail(email: String) {
        guard isValid(email: email) else {
            OptiLoggerMessages.logEmailNotValid()
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
        return !userId.isEmpty && (userId != "none") && (userId != "undefined") && !userId.contains("undefine") && !(userId == "null")
    }

    private func isValid(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
