//  Copyright © 2017 Optimove. All rights reserved.

import UIKit.UIApplication
import UserNotifications
import OptimoveCore

public typealias OptimoveEvent = OptimoveCore.OptimoveEvent

/// The Optimove SDK for iOS - a realtime customer data platform.
/// The integration guide: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki
/// - WARNING:
///  To initialize and configure SDK using `Optimove.configure(for:)` first.
@objc public final class Optimove: NSObject {

    /// The current OptimoveSDK version string value.
    public static let version = SDKVersion

    private let deviceStateObserver: DeviceStateObserver
    private let factory: MainFactory
    private let serviceLocator: ServiceLocator
    private let synchronizer: Synchronizer
    private var storage: OptimoveStorage

    /// The shared instance of Optimove SDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private override init() {
        serviceLocator = ServiceLocator()
        factory = MainFactory(serviceLocator: serviceLocator)
        storage = serviceLocator.storage()
        synchronizer = serviceLocator.synchronizer()
        deviceStateObserver = serviceLocator.deviceStateObserver(
            coreEventFactory: factory.coreEventFactory()
        )
        super.init()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        /// FUTURE: To merge configure call with init.
        shared.serviceLocator.loggerInitializator().initialize()
        shared.serviceLocator.newTenantInfoHandler().handle(tenantInfo)
        shared.deviceStateObserver.start()
        shared.startSDK { _ in }
    }

}

// MARK: - Event API call

extension Optimove {

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - parameters: The dictionary of attributes.
    @objc public func reportEvent(name: String, parameters: [String: Any] = [:]) {
        let customEvent = CommonOptimoveEvent(name: name, parameters: parameters)
        synchronizer.handle(.report(event: customEvent))
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public func reportEvent(_ event: OptimoveEvent) {
        synchronizer.handle(.report(event: event))
    }

}

// MARK: - ScreenVisit API call

extension Optimove {

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @objc public func setScreenVisit(screenTitle: String, screenCategory: String? = nil) {
        let screenTitle = screenTitle.trimmingCharacters(in: .whitespaces)
        Logger.info("Report a screen event w/title: \(screenTitle)")
        let validationResult = ScreenVisitValidator.validate(screenTitle: screenTitle)
        guard validationResult == .valid else { return }
        tryCatch {
            synchronizer.handle(
                .reportScreenEvent(
                    title: screenTitle,
                    category: screenCategory
                )
            )
        }
    }


    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenPathArray: An array of breadcrumbs – an UI path to the screen.
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @available(*, deprecated, renamed: "setScreenVisit(screenTitle:screenCategory:)")
    @objc public func setScreenVisit(screenPathArray: [String], screenTitle: String, screenCategory: String? = nil) {
        setScreenVisit(screenTitle: screenTitle, screenCategory: screenCategory)
    }

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenPath: An UI path to the screen.
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @available(*, deprecated, renamed: "setScreenVisit(screenTitle:screenCategory:)")
    @objc public func setScreenVisit(screenPath: String,
                                     screenTitle: String,
                                     screenCategory: String? = nil) {
        setScreenVisit(screenTitle: screenTitle, screenCategory: screenCategory)
    }

}

// MARK: - SetUserID API call

extension Optimove {

    /// Set a user ID and a user email.
    ///
    /// - Parameters:
    ///   - sdkId: The user unique identifier.
    ///   - email: The user email.
    @objc public func registerUser(sdkId: String, email: String) {
        setUserId(sdkId)
        setUserEmail(email: email)
    }

    /// Set a user ID to the Optimove SDK.
    ///
    /// - Parameter userID: The user unique identifier.
    @objc public func setUserId(_ userID: String) {
        let userID = userID.trimmingCharacters(in: .whitespaces)
        let validationResult = UserIDValidator(storage: storage).validateNewUserID(userID)
        guard validationResult == .valid else { return }
        NewUserIDHandler(storage: storage).handle(userID: userID)
        synchronizer.handle(.setUserId)
        synchronizer.handle(.migrateUser)
    }

    /// Set a user email to the Optimove SDK.
    ///
    /// - Parameter email: The user email.
    @objc public func setUserEmail(email: String) {
        let validationResult = EmailValidator(storage: storage).isValid(email)
        guard validationResult == .valid else { return }
        NewEmailHandler(storage: storage).handle(email: email)
        tryCatch {
            reportEvent(try factory.coreEventFactory().createEvent(.setUserEmail))
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
        return false
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
        let notificationListener = serviceLocator.notificationListener()
        let result = notificationListener.isOptipush(notification: notification)
        if result {
            notificationListener.willPresent(
                notification: notification,
                withCompletionHandler: completionHandler
            )
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
        let validationResult = APNsTokenValidator(storage: serviceLocator.storage())
        if validationResult.validate(token: deviceToken) == .new {
            Logger.debug("New APNS token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
            synchronizer.handle(.deviceToken(token: deviceToken))
        }
    }

    /// User authorization is required for applications to notify the user using UNUserNotificationCenter via both local and remote notifications.
    ///
    /// - Parameter fromUserNotificationCenter: A response from
    @objc public func didReceivePushAuthorization(fromUserNotificationCenter granted: Bool) {
        tryCatch {
            let optInService = serviceLocator.optInService(coreEventFactory: factory.coreEventFactory())
            try optInService.didPushAuthorization(isGranted: granted)
        }
    }

    /// Request to subscribe to test campaign topics
    @available(*, deprecated, message: "No need to calls start test mode.")
    @objc public func startTestMode() {

    }

    /// Request to unsubscribe from test campaign topics
    @objc public func stopTestMode() {
        
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

    /// The method use to fetch tenant config, initialize Optimove SDK and control this process.
    /// - Parameter completion: A result of initializtion.
    func startSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        guard RunningFlagsIndication.isSdkNeedInitializing else {
            Logger.info("Skip initializtion since Optimove SDK already running.")
            completion(.success(()))
            return
        }
        RunningFlagsIndication.isInitializerRunning.toggle()
        serviceLocator.installationIdGenerator().generate()
        serviceLocator.newVisitorIdGenerator().generate()
        serviceLocator.firstTimeVisitGenerator().generate()
        let configurationFetcher = serviceLocator.configurationFetcher(operationFactory: factory.operationFactory())
        configurationFetcher.fetch { result in
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

    // MARK: Configuration

    /// Initialization of SDK with a configuration.
    /// - Parameter configuration: A `Configuration` filetype.
    func initialize(with configuration: Configuration) {
        let onStartEventGenerator = OnStartEventGenerator(
            coreEventFactory: factory.coreEventFactory(),
            synchronizer: synchronizer,
            storage: storage
        )
        onStartEventGenerator.generate()
        let initializer = serviceLocator.initializer(
            componentFactory: factory.componentFactory()
        )
        initializer.initialize(with: configuration)
        RunningFlagsIndication.isInitializerRunning.toggle()
        RunningFlagsIndication.isSdkRunning.toggle()
    }

}

// MARK: - Deprecated: SDK state observing

extension Optimove {

    @available(*, deprecated, message: "No need to register for lifecycle events. Use the SDK directly.")
    public func registerSuccessStateListener(_ listener: OptimoveSuccessStateListener) {
        listener.optimove(self, didBecomeActiveWithMissingPermissions: [])
    }

    @available(*, deprecated, message: "No need to unregister from lifecycle events anymore. Use the SDK directly.")
    public func unregisterSuccessStateListener(_ listener: OptimoveSuccessStateListener) { }

}
