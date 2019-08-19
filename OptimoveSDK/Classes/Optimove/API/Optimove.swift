//  Copyright © 2017 Optimove. All rights reserved.

import UIKit
import UserNotifications
import OptimoveCore

protocol OptimoveEventReporting: class {
    func reportEvent(_ event: OptimoveEvent)
    func dispatchQueuedEventsNow()
}

/// The entry point of Optimove.
/// Initialize and configure SDK using `Optimove.shared.configure(for:)`.
@objc public final class Optimove: NSObject {

    private let serviceLocator: ServiceLocator
    private var storage: OptimoveStorage
    private let components: ComponentsPool

    private let stateDelegateQueue = DispatchQueue(label: "com.optimove.sdk_state_delegates")
    private static var swiftStateDelegates: [ObjectIdentifier: OptimoveSuccessStateListenerWrapper] = [:]
    private static var objcStateDelegate: [ObjectIdentifier: OptimoveSuccessStateDelegateWrapper] = [:]

    // MARK: - Initializers

    /// The shared instance of OptimoveSDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private override init() {
        serviceLocator = ServiceLocator()
        components = serviceLocator.componentsPool()
        storage = serviceLocator.storage()
        super.init()

        setup()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        Logger.warn("Optimove: Use tenant config \(tenantInfo.configName)")
        shared.configureLogger()
        Logger.debug("Optimove: configure started.")
        shared.storeTenantInfo(tenantInfo)
        shared.startNormalInitProcess { (sucess) in
            guard sucess else {
                Logger.error("Optimove: configure failed.")
                return
            }
            Logger.info("Optimove: configure finished. ✅")
        }
    }

    // MARK: - Deep Link

    private var deepLinkResponders = [OptimoveDeepLinkResponder]()

    var deepLinkComponents: OptimoveDeepLinkComponents? {
        didSet {
            guard let dlc = deepLinkComponents else {
                return
            }
            for responder in deepLinkResponders {
                responder.didReceive(deepLinkComponent: dlc)
            }
        }
    }
}

// MARK: - Initialization API

extension Optimove {

    func startNormalInitProcess(didSucceed: @escaping ResultBlockWithBool) {
        Logger.info("Start Optimove component initialization from remote.")
        if RunningFlagsIndication.isSdkRunning {
            Logger.debug("Skip normal initializtion since SDK already running")
            didSucceed(true)
            return
        }
        let initializer = serviceLocator.initializer()
        initializer.initializeFromRemoteServer { [initializer] success in
            if success {
                didSucceed(success)
                self.didFinishInitializationSuccessfully()
            } else {
                initializer.initializeFromLocalConfigs { success in
                    didSucceed(success)
                }
            }
        }
    }

    func startUrgentInitProcess(didSucceed: @escaping ResultBlockWithBool) {
        Logger.info("Start Optimove urgent initiazlition process")
        if RunningFlagsIndication.isSdkRunning {
            Logger.debug("Skip urgent initializtion since SDK already running")
            didSucceed(true)
            return
        }
        let initializer = serviceLocator.initializer()
        initializer.initializeFromLocalConfigs { success in
            didSucceed(success)
            if success {
                self.didFinishInitializationSuccessfully()
            }
        }
    }

    func didFinishInitializationSuccessfully() {
        RunningFlagsIndication.isInitializerRunning = false
        RunningFlagsIndication.isSdkRunning = true

        let missingPermissions = serviceLocator.deviceStateMonitor().getMissingPermissions()
        let missingPermissionsObjc = missingPermissions.map { $0.rawValue }
        Optimove.swiftStateDelegates.values.forEach { (wrapper) in
            wrapper.observer?.optimove(self, didBecomeActiveWithMissingPermissions: missingPermissions)
        }
        Optimove.objcStateDelegate.values.forEach { (wrapper) in
            wrapper.observer.optimove(self, didBecomeActiveWithMissingPermissions: missingPermissionsObjc)
        }
    }
}

// MARK: - SDK state observing

//TODO: expose to  @objc
extension Optimove {

    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        if RunningFlagsIndication.isSdkRunning {
            listener.optimove(
                self,
                didBecomeActiveWithMissingPermissions: serviceLocator.deviceStateMonitor().getMissingPermissions()
            )
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
            delegate.optimove(
                self,
                didBecomeActiveWithMissingPermissions: serviceLocator.deviceStateMonitor().getMissingPermissions().map { $0.rawValue }
            )
            return
        }
        stateDelegateQueue.async {
            Optimove.objcStateDelegate[ObjectIdentifier(delegate)] = OptimoveSuccessStateDelegateWrapper(
                observer: delegate
            )
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
    @objc public func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
        ) -> Bool {
        Logger.info("Receive remote notification.")
        guard userInfo[OptimoveKeys.Notification.isOptimoveSdkCommand.rawValue] as? String == "true" else {
            return false
        }
        serviceLocator.notificationListener().didReceiveRemoteNotification(
            userInfo: userInfo,
            didComplete: didComplete
        )
        return true
    }

    @objc public func willPresent(
        notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) -> Bool {
        Logger.info("Received notification in foreground mode.")
        guard notification.request.content.userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true"
            else {
                Logger.debug("Notification should not be handled by optimove")
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
    @objc public func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
        ) -> Bool {
        let userInfo = response.notification.request.content.userInfo
        guard userInfo[OptimoveKeys.Notification.isOptipush.rawValue] as? String == "true" else {
            Logger.debug("User respond to non optimove notification")
            return false
        }
        serviceLocator.notificationListener().didReceive(
            response: response,
            withCompletionHandler: completionHandler
        )
        return true
    }
}

// MARK: - OptiPush related API
extension Optimove {

    /// Request to handle APNS <-> FCM regisration process
    ///
    /// - Parameter deviceToken: A token that was received in the appDelegate callback
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        components.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        // TODO: It unneccessary to keep a device token after state-listener will go out,
        // and an internal buffer will be introduced.
        if !RunningFlagsIndication.isComponentRunning(.optiPush) {
            storage.apnsToken = deviceToken
        }
    }

    private var optimoveTestTopic: String {
        return "test_ios_\(Bundle.main.bundleIdentifier ?? "")"
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
    func registerToOptipushTopic(_ topic: String) {
        components.subscribeToTopic(topic: topic)
    }

    /// Request to unregister from topic
    ///
    /// - Parameter topic: The topic name
    func unregisterFromOptipushTopic(_ topic: String) {
        components.unsubscribeFromTopic(topic: topic)
    }

    func performRegistration() {
        components.performRegistration()
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
        if let index = self.deepLinkResponders.firstIndex(of: responder) {
            deepLinkResponders.remove(at: index)
        }
    }
}

extension Optimove: OptimoveEventReporting {

    func dispatchQueuedEventsNow() {
        components.dispatchNow()
    }

}

// MARK: - OptiTrack related API

extension Optimove {

    /// Validate the permissions of the client to use Optitrack component and if permit sends the
    /// report to the appropriate handler.
    ///
    /// - Parameters:
    ///   - event: optimove event object
    @objc public func reportEvent(_ event: OptimoveEvent) {
        do {
            try components.report(event: event)

            // FIXME: Handle it in a different way. If needed
            if !RunningFlagsIndication.isComponentRunning(.realtime) {
                if event.name == OptimoveKeys.Configuration.setUserId.rawValue {
                    storage.realtimeSetUserIdFailed = true
                } else if event.name == OptimoveKeys.Configuration.setEmail.rawValue {
                    storage.realtimeSetEmailFailed = true
                }
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    @objc public func reportEvent(name: String, parameters: [String: Any]) {
        let customEvent = SimpleCustomEvent(name: name, parameters: parameters)
        reportEvent(customEvent)
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
            Logger.error("Optimove: User id '\(userId)' is not valid.")
            return
        }

        //TODO: Move to Optipush?
        if storage.customerID == nil {
            storage.isFirstConversion = true
        } else if userId != storage.customerID {
            OptiLoggerStreamsContainer.log(
                level: .debug,
                fileName: #file,
                methodName: #function,
                logModule: "Optimove",
                "user id changed from '\(storage.customerID ?? "nil")' to '\(userId)'"
            )
            if storage.isRegistrationSuccess == true {
                // send the first_conversion flag only if no previous registration has succeeded
                storage.isFirstConversion = false
            }
        } else {
            Logger.warn("Optimove: User id '\(userId)' was already set in.")
            return
        }
        storage.isRegistrationSuccess = false
        //

        let initialVisitorId = storage.initialVisitorId!
        let updatedVisitorId = getVisitorId(from: userId)
        storage.visitorID = updatedVisitorId
        storage.customerID = userId

        components.setUserId(userId)
        let setUserIdEvent = SetUserIdEvent(
            originalVistorId: initialVisitorId,
            userId: userId,
            updateVisitorId: storage.visitorID!
        )
        reportEvent(setUserIdEvent)
        components.performRegistration()
    }

    /// Produce a 16 characters string represents the visitor ID of the client
    ///
    /// - Parameter userId: The user ID which is the source
    /// - Returns: THe generated visitor ID
    private func getVisitorId(from userId: String) -> String {
        return userId.sha1().prefix(16).description.lowercased()
    }

    /// Send the sdk id and the user email
    ///
    /// - Parameters:
    ///   - email: The user email
    ///   - sdkId: The user ID

    @available(*, deprecated, renamed: "registerUser(sdkId:email:)")
    @objc public func registerUser(email: String, sdkId: String) {
        registerUser(sdkId: sdkId, email: email)
    }

    /// Send the sdk id and the user email
    ///
    /// - Parameters:
    ///   - sdkId: The user ID
    ///   - email: The user email
    @objc public func registerUser(sdkId: String, email: String) {
        setUserId(sdkId)
        setUserEmail(email: email)
    }

    /// Call for the SDK to send the user email to its components
    ///
    /// - Parameter email: The user email
    @objc public func setUserEmail(email: String) {
        guard isValid(email: email) else {
            Logger.error("Optimove: Email is not valid")
            return
        }
        storage.userEmail = email
        reportEvent(SetUserEmailEvent(email: email))
    }

    /// Validate that the user id that provided by the client, feets with optimove conditions for valid user id
    ///
    /// - Parameter userId: the client user id
    /// - Returns: An indication of the validation of the provided user id
    private func isValid(userId: String) -> Bool {
        return !userId.isEmpty && (userId != "none") && (userId != "undefined") && !userId.contains("undefine") && !(
            userId == "null"
        )
    }

    private func isValid(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}

extension Optimove {

    // MARK: - Report screen visit

    @objc public func setScreenVisit(screenPathArray: [String], screenTitle: String, screenCategory: String? = nil) {
        Logger.debug("User ask to report screen event.")
        guard !screenTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            Logger.error("Trying to report screen visit with empty title")
            return
        }
        let path = screenPathArray.joined(separator: "/")
        setScreenVisit(screenPath: path, screenTitle: screenTitle, screenCategory: screenCategory)
    }

    @objc public func setScreenVisit(screenPath: String, screenTitle: String, screenCategory: String? = nil) {
        let screenTitle = screenTitle.trimmingCharacters(in: .whitespaces)
        var screenPath = screenPath.trimmingCharacters(in: .whitespaces)
        guard !screenTitle.isEmpty else {
            Logger.error("Trying to report screen visit with empty title")
            return
        }
        guard !screenPath.isEmpty else {
            Logger.error("Trying to report screen visit with empty path")
            return
        }

        if screenPath.starts(with: "/") {
            screenPath = String(screenPath[screenPath.index(after: screenPath.startIndex)...])
        }
        if let customUrl = removeUrlProtocol(path: screenPath)
            .lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {

            var path = customUrl.last != "/" ? "\(customUrl)/" : "\(customUrl)"

            path = "\(Bundle.main.bundleIdentifier!)/\(path)".lowercased()

            try? components.reportScreenEvent(
                customURL: path,
                pageTitle: screenTitle,
                category: screenCategory
            )
        }
    }

    private func removeUrlProtocol(path: String) -> String {
        var result = path
        for prefix in ["https://www.", "http://www.", "https://", "http://"] {
            if result.hasPrefix(prefix) {
                result.removeFirst(prefix.count)
                break
            }
        }
        return result
    }
}

private extension Optimove {

    // MARK: - Private Methods

    /// Stores the user information that was provided during configuration.
    ///
    /// - Parameter info: user unique info
    func storeTenantInfo(_ info: OptimoveTenantInfo) {
        storage.tenantToken = info.tenantToken
        storage.version = info.configName
        storage.configurationEndPoint = Endpoints.Remote.TenantConfig.url

        Logger.debug(
            """
            Stored user info in local storage:
            token: \(info.tenantToken)
            version: \(info.configName)
            end point: \(Endpoints.Remote.TenantConfig.url.absoluteString)
            """
        )
    }

    func configureLogger() {
        MultiplexLoggerStream.add(stream: ConsoleLoggerStream())
        if SDK.isStaging {
            MultiplexLoggerStream.add(stream: RemoteLoggerStream(tenantId: storage.siteID ?? -1))
        }
    }

    func setup() {
        setUserAgent()
        setVisitorIdIfNeeded()
    }

    func setUserAgent() {
        storage.userAgent = SDKDevice.evaluateUserAgent()
    }

    func setVisitorIdIfNeeded() {
        if storage.visitorID == nil {
            let uuid = UUID().uuidString
            let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
            let start = sanitizedUUID.startIndex
            let end = sanitizedUUID.index(start, offsetBy: 16)
            storage.initialVisitorId = String(sanitizedUUID[start..<end]).lowercased()
            storage.visitorID = storage.initialVisitorId
        }
    }

}
