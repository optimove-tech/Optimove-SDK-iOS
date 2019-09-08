//  Copyright © 2017 Optimove. All rights reserved.

import UIKit.UIApplication
import UserNotifications
import OptimoveCore

/// The entry point of Optimove.
/// Initialize and configure SDK using `Optimove.configure(for:)`.
@objc public final class Optimove: NSObject {

    private let serviceLocator: ServiceLocator
    private let mainFactory: MainFactory
    private var storage: OptimoveStorage
    private let handlers: HandlersPool
    private let stateListener: DeprecatedStateListener

    /// The shared instance of OptimoveSDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private override init() {
        serviceLocator = ServiceLocator()
        mainFactory = MainFactory(serviceLocator: serviceLocator)
        handlers = serviceLocator.handlersPool()
        storage = serviceLocator.storage()
        stateListener = DeprecatedStateListener()
        super.init()

        setup()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        shared.configureLogger()
        Logger.warn("Tenant config \(tenantInfo.configName)")
        shared.storeTenantInfo(tenantInfo)
        Logger.debug("Configure started.")
        shared.startNormalInitProcess { (sucess) in
            guard sucess else {
                Logger.error("Configure failed. 🛑")
                return
            }
            Logger.info("Configure finished. ✅")
        }
    }

}

// MARK: - Notification API call

extension Optimove {

    /// Tells the Optimove SDK that a remote notification arrived that indicates there is data to be fetched.
    ///
    /// - Parameters:
    ///   - userInfo: A dictionary that contains information related to the remote notification.
    ///   - completionHandler: The block to execute when the download operation is complete.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
        ) -> Bool {
        Logger.info("Receive remote notification.")
        let notificationListener = serviceLocator.notificationListener()
        let result = notificationListener.isOptimoveSdkCommand(userInfo: userInfo)
        if result {
            startUrgentInitProcess { (success) in
                guard success else { return }
                notificationListener.didReceiveRemoteNotification(
                    userInfo: userInfo,
                    didComplete: didComplete
                )
            }
        }
        return result
    }

    /// Asks the Optimove SDK how to handle a notification that arrived while the app was running in the foreground.
    ///
    /// - Parameters:
    ///   - notification: The notification that is about to be delivered.
    ///   - completionHandler: The block to execute when the download operation is complete.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public func willPresent(
        notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) -> Bool {
        Logger.info("Received notification in foreground mode.")
        let notificationListener = serviceLocator.notificationListener()
        let result = notificationListener.isOptipush(notification: notification)
        if result {
            notificationListener.willPresent(notification: notification, withCompletionHandler: completionHandler)
        }
        return result
    }

    /// Asks the Optimove SDK to process the user's response to a delivered notification.
    ///
    /// - Parameters:
    ///   - response: The user’s response to the notification.
    ///   - completionHandler: The block to execute when you have finished processing the user’s response.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
        ) -> Bool {
        let notificationListener = serviceLocator.notificationListener()
        let result = notificationListener.isOptipush(notification: response.notification)
        if result {
            startUrgentInitProcess { (success) in
                guard success else { return }
                notificationListener.didReceive(
                    response: response,
                    withCompletionHandler: completionHandler
                )
            }
        }
        return result
    }
}

// MARK: - OptiPush API call

extension Optimove {

    /// Tells the Optimove SDK that the app successfully registered with Apple Push Notification service (APNs).
    ///
    /// - Parameter deviceToken: A token that was received from the AppDelegate.
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        reportPushable(PushableOperationContext(.deviceToken(token: deviceToken)))
    }

    /// Request to subscribe to test campaign topics
    @objc public func startTestMode() {
        reportPushable(PushableOperationContext(.subscribeToTopic(topic: optimoveTestTopic)))
    }

    /// Request to unsubscribe from test campaign topics
    @objc public func stopTestMode() {
        reportPushable(PushableOperationContext(.unsubscribeFromTopic(topic: optimoveTestTopic)))
    }
}

// MARK: - Event API call

extension Optimove {

    @objc public func reportEvent(name: String, parameters: [String: Any]) {
        let customEvent = SimpleCustomEvent(name: name, parameters: parameters)
        reportEventable(context: EventableOperationContext(.report(event: customEvent)))
    }

    /// Validate the permissions of the client to use Optitrack component and if permit sends the
    /// report to the appropriate handler.
    ///
    /// - Parameters:
    ///   - event: optimove event object
    @objc public func reportEvent(_ event: OptimoveEvent) {
        reportEventable(context: EventableOperationContext(.report(event: event)))
    }

}

// MARK: - SetUserID API call

extension Optimove {

    /// validate the permissions of the client to use optitrack component and if permit validate the sdkId content and sends:
    /// - conversion request to the DB
    /// - new customer registraion to the registration end point
    ///
    /// - Parameter sdkId: the client unique identifier
    @objc public func setUserId(_ sdkId: String) {
        let userId = sdkId.trimmingCharacters(in: .whitespaces)
        let validationResult = UserIDValidator(storage: storage).validateNewUserID(userId)
        guard validationResult == .valid else { return }
        updateStorage(userId: userId)
        do {
            reportEvent(try mainFactory.coreEventFactory().createEvent(.setUserId))
            try handlers.pushableHandler.handle(PushableOperationContext(.performRegistration))
        } catch {
            Logger.error(error.localizedDescription)
        }
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
        guard EmailValidator.isValid(email) else {
            Logger.error("Optimove: Email is not valid")
            return
        }
        storage.userEmail = email
        reportEvent(SetUserEmailEvent(email: email))
    }

}

// MARK: - ScreenVisit API call

extension Optimove {

    @objc public func setScreenVisit(screenPathArray: [String], screenTitle: String, screenCategory: String? = nil) {
        setScreenVisit(screenPath: screenPathArray.joined(separator: "/"),
                       screenTitle: screenTitle,
                       screenCategory: screenCategory)
    }

    @objc public func setScreenVisit(screenPath: String, screenTitle: String, screenCategory: String? = nil) {
        let screenPath = screenPath.trimmingCharacters(in: .whitespaces)
        let screenTitle = screenTitle.trimmingCharacters(in: .whitespaces)
        Logger.debug("Report screen event w/ title: \(screenTitle)")
        let validationResult = ScreenVisitValidator.validate(screenPath: screenPath, screenTitle: screenTitle)
        guard validationResult == .valid else { return }
        do {
            try handlers.eventableHandler.handle(
                EventableOperationContext(
                    .reportScreenEvent(
                        customURL: try ScreenVisitPreprocessor.process(screenPath),
                        pageTitle: screenTitle,
                        category: screenCategory
                    )
                )
            )
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}

// MARK: - OptimoveDeepLinkResponding

extension Optimove: OptimoveDeepLinkResponding {

    @objc public func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        serviceLocator.deeplinkService().register(deepLinkResponder: responder)
    }

    @objc public func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        serviceLocator.deeplinkService().unregister(deepLinkResponder: responder)
    }
}

// MARK: - Private

private extension Optimove {

    // MARK: Initialization

    func startNormalInitProcess(didSucceed: @escaping ResultBlockWithBool) {
        Logger.info("Start initialization from remote.")
        if RunningFlagsIndication.isSdkRunning {
            Logger.debug("Skip normal initializtion since SDK already running.")
            didSucceed(true)
            return
        }
        let initializer = mainFactory.initializer()
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
        Logger.info("Start urgent initiazlition process.")
        if RunningFlagsIndication.isSdkRunning {
            Logger.debug("Skip urgent initializtion since SDK already running")
            didSucceed(true)
            return
        }
        let initializer = mainFactory.initializer()
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
        stateListener.onInitializationSuccessfully(self)
    }

    /// Stores the user information that was provided during configuration.
    ///
    /// - Parameter info: user unique info
    func storeTenantInfo(_ info: OptimoveTenantInfo) {
        storage.tenantToken = info.tenantToken
        storage.version = info.configName
        storage.configurationEndPoint = Endpoints.Remote.TenantConfig.url

        Logger.debug(
            """
            Stored user info in local storage. Source:
            endpoint: \(Endpoints.Remote.TenantConfig.url.absoluteString)
            token: \(info.tenantToken)
            version: \(info.configName)
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
        SDKDevice.evaluateUserAgent(completion: { [weak self] (userAgent) in
            self?.storage.userAgent = userAgent
        })
    }

    func setVisitorIdIfNeeded() {
        if storage.visitorID == nil {
            let uuid = UUID().uuidString
            let sanitizedUUID = uuid.replacingOccurrences(of: "-", with: "")
            storage.initialVisitorId = VisitorIDPreprocessor.process(sanitizedUUID)
            storage.visitorID = storage.initialVisitorId
        }
    }

    // MARK: OptiTrack private

    private func reportEventable(context: EventableOperationContext) {
        do {
            // TODO: Normilize event
            try handlers.eventableHandler.handle(context)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    // MARK: OptiPush private

    private var optimoveTestTopic: String {
        return "test_ios_\(Bundle.main.bundleIdentifier ?? "")"
    }

    private func reportPushable(_ context: PushableOperationContext) {
        do {
            try handlers.pushableHandler.handle(context)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    // MARK: SetUsetID private

    private func updateStorage(userId: String) {
        if storage.customerID == nil {
            storage.isFirstConversion = true
        } else if userId != storage.customerID {
            Logger.debug("user id changed from '\(storage.customerID ?? "nil")' to '\(userId)'")
            if storage.isRegistrationSuccess == true {
                // send the first_conversion flag only if no previous registration has succeeded
                storage.isFirstConversion = false
            }
        }
        storage.isRegistrationSuccess = false
        storage.visitorID = VisitorIDPreprocessor.process(userId)
        storage.customerID = userId
    }

}

// MARK: - Deprecated: SDK state observing

extension Optimove {

    @available(*, deprecated, message: "This method will be deleted in the next version. Instead of subscribing as an listener use Optimove SDK directly.")
    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        stateListener.registerSuccessStateListener(optimove: self, listener: listener)
    }

    @available(*, deprecated, message: "This method will be deleted in the next version. Instead of subscribing as an listener use Optimove SDK directly.")
    public func unregisterSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        stateListener.unregisterSuccessStateListener(optimove: self, listener: listener)
    }

}
