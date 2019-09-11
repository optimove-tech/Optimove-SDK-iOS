//  Copyright © 2017 Optimove. All rights reserved.

import UIKit.UIApplication
import UserNotifications
import OptimoveCore

/// The entry point of Optimove.
/// Initialize and configure SDK using `Optimove.configure(for:)`.
@objc public final class Optimove: NSObject {

    private let serviceLocator: ServiceLocator
    private var storage: OptimoveStorage
    private let handlers: HandlersPool
    private let factory: MainFactory
    private let queue: DispatchQueue
    private let stateListener: DeprecatedStateListener
    private let deviceStateObserver: DeviceStateObserver

    /// The shared instance of OptimoveSDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private override init() {
        serviceLocator = ServiceLocator()
        factory = MainFactory(serviceLocator: serviceLocator)
        handlers = serviceLocator.handlersPool()
        storage = serviceLocator.storage()
        stateListener = DeprecatedStateListener()
        deviceStateObserver = serviceLocator.deviceStateObserver(coreEventFactory: factory.coreEventFactory())
        queue = DispatchQueue(label: "com.optimove.sdk", qos: .utility)
        super.init()

        setup()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        shared.queue.async {
            shared.serviceLocator.loggerInitializator().initialize()
            shared.serviceLocator.newTenantInfoHandler().handle(tenantInfo)
            shared.deviceStateObserver.start()
            shared.startSDK { _ in }
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
        Logger.info("Receive a remote notification.")
        let notificationListener = serviceLocator.notificationListener(
            coreEventFactory: factory.coreEventFactory()
        )
        let result = notificationListener.isOptimoveSdkCommand(userInfo: userInfo)
        if result {
            queue.async {
                self.startSDK { result in
                    guard result.isSuccessful else { return }
                    notificationListener.didReceiveRemoteNotification(
                        userInfo: userInfo,
                        didComplete: didComplete
                    )
                }
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
        Logger.info("Received a notification in foreground mode.")
        let notificationListener = serviceLocator.notificationListener(
            coreEventFactory: factory.coreEventFactory()
        )
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
        Logger.info("User produce a response for a notificaiton.")
        let notificationListener = serviceLocator.notificationListener(
            coreEventFactory: factory.coreEventFactory()
        )
        let result = notificationListener.isOptipush(notification: response.notification)
        if result {
            queue.async {
                self.startSDK { result in
                    guard result.isSuccessful else { return }
                    notificationListener.didReceive(
                        response: response,
                        withCompletionHandler: completionHandler
                    )
                }
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
        queue.async {
            self.reportPushable(PushableOperationContext(.deviceToken(token: deviceToken)))
        }
    }

    /// Request to subscribe to test campaign topics
    @objc public func startTestMode() {
        queue.async {
            do {
                let testTopic = OptimoveKeys.testTopicPrefix + (try Bundle.getApplicationNameSpace())
                self.reportPushable(PushableOperationContext(.subscribeToTopic(topic: testTopic)))
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    /// Request to unsubscribe from test campaign topics
    @objc public func stopTestMode() {
        queue.async {
            do {
                let testTopic = OptimoveKeys.testTopicPrefix + (try Bundle.getApplicationNameSpace())
                self.reportPushable(PushableOperationContext(.unsubscribeFromTopic(topic: testTopic)))
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
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
        queue.async {
            let customEvent = CommonOptimoveEvent(name: name, parameters: parameters)
            self.reportEventable(EventableOperationContext(.report(event: customEvent)))
        }
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public func reportEvent(_ event: OptimoveEvent) {
        queue.async {
            self.reportEventable(EventableOperationContext(.report(event: event)))
        }
    }

}

// MARK: - SetUserID API call

extension Optimove {

    /// Set a User ID value to Optimove SDK.
    ///
    /// - Parameter userID: A client unique identifier
    @objc public func setUserId(_ userID: String) {
        queue.async {
            let userID = userID.trimmingCharacters(in: .whitespaces)
            let validationResult = UserIDValidator(storage: self.storage).validateNewUserID(userID)
            guard validationResult == .valid else { return }
            NewUserIDHandler(storage: self.storage).handle(userID: userID)
            self.reportEventable(EventableOperationContext(.setUserId(userId: userID)))
            self.reportPushable(PushableOperationContext(.performRegistration))
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
        queue.async {
            let validationResult = EmailValidator.isValid(email)
            guard validationResult == .valid else { return }
            self.storage.userEmail = email
            self.reportEvent(SetUserEmailEvent(email: email))
        }
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
        queue.async {
            let screenPath = screenPath.trimmingCharacters(in: .whitespaces)
            let screenTitle = screenTitle.trimmingCharacters(in: .whitespaces)
            Logger.info("Report a screen event w/title: \(screenTitle)")
            let validationResult = ScreenVisitValidator.validate(screenPath: screenPath, screenTitle: screenTitle)
            guard validationResult == .valid else { return }
            do {
                try self.handlers.eventableHandler.handle(
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
        guard RunningFlagsIndication.isSdkNeedInitializing else {
            Logger.info("Skip initializtion since Optimove SDK already running.")
            completion(.success(()))
            return
        }
        generateAndSendOnStartEvents()
        RunningFlagsIndication.isInitializerRunning.toggle()
        let configurationFetcher = serviceLocator.configurationFetcher(operationFactory: factory.operationFactory())
        configurationFetcher.fetch { result in
            self.queue.async {
                switch result {
                case let .success(configuration):
                    self.initialize(with: configuration)
                    Logger.info("Initialization finished. ✅")
                    completion(.success(()))
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    Logger.error("Initialization failed. 🛑")
                    completion(.failure(error))
                }
            }
        }
    }

    func generateAndSendOnStartEvents() {
        do {
            try OnStartEventGenerator(coreEventFactory: factory.coreEventFactory()).generate().forEach { event in
                try handlers.eventableHandler.handle(.init(.report(event: event)))
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    //  MARK: Configuration

    func setup() {
        SDKDevice.evaluateUserAgent(completion: { (userAgent) in
            self.storage.userAgent = userAgent
        })
        serviceLocator.newVisitorIdGenerator().generate()
    }

    func initialize(with configuration: Configuration) {
        let initializer = serviceLocator.initializer(
            componentFactory: factory.componentFactory()
        )
        initializer.initialize(with: configuration)
        RunningFlagsIndication.isInitializerRunning.toggle()
        RunningFlagsIndication.isSdkRunning.toggle()
        stateListener.onInitializationSuccessfully(self)
    }

    // MARK: OptiTrack private

    private func reportEventable(_ context: EventableOperationContext) {
        do {
            try handlers.eventableHandler.handle(context)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    // MARK: OptiPush private

    private func reportPushable(_ context: PushableOperationContext) {
        do {
            try handlers.pushableHandler.handle(context)
        } catch {
            Logger.error(error.localizedDescription)
        }
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
