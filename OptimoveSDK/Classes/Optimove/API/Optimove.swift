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
        shared.storeTenantInfo(tenantInfo)
        shared.startSDK { _ in }
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
            startSDK { result in
                guard result.isSuccessful else { return }
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
        Logger.info("Received notification in foreground mode.")
        let notificationListener = serviceLocator.notificationListener()
        let result = notificationListener.isOptipush(notification: response.notification)
        if result {
            startSDK { result in
                guard result.isSuccessful else { return }
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

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - parameters: The dictionary of attributes.
    @objc public func reportEvent(name: String, parameters: [String: Any]) {
        let customEvent = SimpleCustomEvent(name: name, parameters: parameters)
        reportEventable(context: EventableOperationContext(.report(event: customEvent)))
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public func reportEvent(_ event: OptimoveEvent) {
        reportEventable(context: EventableOperationContext(.report(event: event)))
    }

}

// MARK: - SetUserID API call

extension Optimove {

    /// Set a User ID value to Optimove SDK.
    ///
    /// - Parameter userID: A client unique identifier
    @objc public func setUserId(_ userID: String) {
        let userID = userID.trimmingCharacters(in: .whitespaces)
        let validationResult = UserIDValidator(storage: storage).validateNewUserID(userID)
        guard validationResult == .valid else { return }
        updateStorage(userId: userID)
        do {
            reportEvent(try mainFactory.coreEventFactory().createEvent(.setUserId))
            try handlers.pushableHandler.handle(PushableOperationContext(.performRegistration))
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    /// Set a User ID and the user email
    ///
    /// - Parameters:
    ///   - sdkId: Aa client unique identifier
    ///   - email: An user's email
    @objc public func registerUser(sdkId: String, email: String) {
        setUserId(sdkId)
        setUserEmail(email: email)
    }

    /// Call for the SDK to send the user email to its components
    ///
    /// - Parameter email: The user email
    @objc public func setUserEmail(email: String) {
        let validationResult = EmailValidator.isValid(email)
        guard validationResult == .valid else { return }
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
        Logger.info("Report screen event w/title: \(screenTitle)")
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

    func startSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        guard RunningFlagsIndication.isSdkNeedInitializing() else {
            Logger.info("Skip normal initializtion since SDK already running.")
            completion(.success(()))
            return
        }
        RunningFlagsIndication.isInitializerRunning.toggle()
        let initializer = mainFactory.initializer()
        initializer.initialize { result in
            switch result {
            case .success:
                RunningFlagsIndication.isInitializerRunning.toggle()
                RunningFlagsIndication.isSdkRunning.toggle()
                self.stateListener.onInitializationSuccessfully(self)
            case .failure:
                break
            }
            completion(result)
        }
    }

    //  MARK: Configuration

    /// Stores the user information that was provided during configuration.
    ///
    /// - Parameter info: user unique info
    func storeTenantInfo(_ info: OptimoveTenantInfo) {
        storage.tenantToken = info.tenantToken
        storage.version = info.configName
        storage.configurationEndPoint = Endpoints.Remote.TenantConfig.url

        Logger.info(
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
            Logger.info("user id changed from '\(storage.customerID ?? "nil")' to '\(userId)'")
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
