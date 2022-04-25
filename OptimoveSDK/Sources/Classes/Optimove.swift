//  Copyright © 2017 Optimove. All rights reserved.

import UIKit.UIApplication
import UserNotifications
import OptimoveCore

public typealias Event = OptimoveCore.Event
typealias Logger = OptimoveCore.Logger

/// The Optimove SDK for iOS - a realtime customer data platform.
/// The integration guide: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki
/// - WARNING:
///  To initialize and configure SDK using `Optimove.configure(for:)` first.
@objc public final class Optimove: NSObject {

    /// The current OptimoveSDK version string value.
    public static let version = OptimoveCore.SDKVersion

    /// The shared instance of Optimove SDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private let container: Container
    private var config: OptimoveConfig!

    private override init() {
        self.container = Assembly().makeContainer()
        container.resolve { serviceLocator in
            serviceLocator.loggerInitializator().initialize()
            serviceLocator.newVisitorIdGenerator().generate()
        }
        super.init()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        /// FUTURE: To merge configure call with init.
        shared.container.resolve { serviceLocator in
            serviceLocator.newTenantInfoHandler().handle(tenantInfo)
            serviceLocator.deviceStateObserver().start()
            shared.startSDK { _ in }
        }
    }

    public static func initialize(with config: OptimoveConfig) {
        shared.config = config

        if config.isOptimoveConfigured(), let tenantInfo = config.tenantInfo {
            Optimove.configure(for: tenantInfo)
        }

        if config.isOptimobileConfigured(), let optimobileConfig = config.optimobileConfig {
            shared.container.resolve { serviceLocator in
                guard let visitorId = try? serviceLocator.storage().getInitialVisitorId() else {
                    return
                }

                Optimobile.initialize(config: optimobileConfig, initialVisitorId: visitorId)
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
    @objc public func reportEvent(name: String, parameters: [String: Any] = [:]) {
        container.resolve { serviceLocator in
            let tenantEvent = TenantEvent(name: name, context: parameters)
            serviceLocator.pipeline().deliver(.report(events: [tenantEvent]))
        }
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - parameters: The dictionary of attributes.
    @objc public static func reportEvent(name: String, parameters: [String: Any] = [:]) {
        shared.reportEvent(name: name, parameters: parameters)
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public func reportEvent(_ event: OptimoveEvent) {
        container.resolve { serviceLocator in
            let tenantEvent = TenantEvent(name: event.name, context: event.parameters)
            serviceLocator.pipeline().deliver(.report(events: [tenantEvent]))
        }
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public static func reportEvent(_ event: OptimoveEvent) {
        shared.reportEvent(event)
    }

}

// MARK: - ScreenVisit API call

extension Optimove {

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @objc public func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
        let title = title.trimmingCharacters(in: .whitespaces)
        let validationResult = ScreenVisitValidator.validate(screenTitle: title)
        guard validationResult == .valid else { return }
        container.resolve { serviceLocator in
            tryCatch {
                let factory = serviceLocator.coreEventFactory()
                let event = try factory.createEvent(.pageVisit(title: title, category: category))
                serviceLocator.pipeline().deliver(.report(events: [event]))
            }
        }
    }

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @objc public static func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
        shared.reportScreenVisit(screenTitle: title, screenCategory: category)
    }
}

// MARK: - SetUserID API call

extension Optimove {

    /// Set a user ID and a user email.
    ///
    /// - Parameters:
    ///   - sdkId: The user unique identifier.
    ///   - email: The user email.
    @objc public func registerUser(sdkId userID: String, email: String) {
        if config.isOptimoveConfigured() {
            let function: (ServiceLocator) -> Void = { serviceLocator in
                tryCatch {
                    let user = User(userID: userID)
                    let setUserIdEvent = try self._setUser(user, serviceLocator)
                    let setUserEmailEvent: Event = try self._setUserEmail(email, serviceLocator)
                    serviceLocator.pipeline().deliver(.report(events: [setUserIdEvent, setUserEmailEvent]))
                    if UserValidator(storage: serviceLocator.storage()).validateNewUser(user) == .valid {
                        serviceLocator.pipeline().deliver(.setInstallation)
                    }
                }
            }
            container.resolve(function)
        }

        if config.isOptimobileConfigured() {
            Optimobile.associateUserWithInstall(userIdentifier: userID)
        }
    }

    /// Set a user ID and a user email.
    ///
    /// - Parameters:
    ///   - sdkId: The user unique identifier.
    ///   - email: The user email.
    @objc public static func registerUser(sdkId userID: String, email: String) {
        shared.registerUser(sdkId: userID, email: email)
    }

    /// Set a user ID to the Optimove SDK.
    ///
    /// - Parameter userID: The user unique identifier.
    @objc public func setUserId(_ userID: String) {
        if config.isOptimoveConfigured() {
            let function: (ServiceLocator) -> Void = { serviceLocator in
                tryCatch {
                    let user = User(userID: userID)
                    let event = try self._setUser(user, serviceLocator)
                    serviceLocator.pipeline().deliver(.report(events: [event]))
                    if UserValidator(storage: serviceLocator.storage()).validateNewUser(user) == .valid {
                        serviceLocator.pipeline().deliver(.setInstallation)
                    }
                }
            }
            container.resolve(function)
        }

        if config.isOptimobileConfigured() {
            Optimobile.associateUserWithInstall(userIdentifier: userID)
        }
    }
    
    /// get visitor id of optimove SDK.
    /// call this function if you need the internal visitor Id of Optimove
    @objc public static func getVisitorID() -> String? {
        return shared.getVisitorID()
    }
    
    private func getVisitorID() -> String? {
        let function: (ServiceLocator) -> String? = { serviceLocator in
            return try? serviceLocator.storage().getVisitorID()
        }
        guard let id = container.resolve(function) else { return nil }
        return id
    }

    /// Set a user ID to the Optimove SDK.
    ///
    /// - Parameter userID: The user unique identifier.
    @objc public static func setUserId(_ userID: String) {
        shared.setUserId(userID)
    }

    private func _setUser(_ user: User, _ serviceLocator: ServiceLocator) throws -> Event {
        return try serviceLocator.coreEventFactory().createEvent(.setUser(user: user))
    }

    /// Set a user email to the Optimove SDK.
    ///
    /// - Parameter email: The user email.
    @objc public func setUserEmail(email: String) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            tryCatch {
                let event: Event = try self._setUserEmail(email, serviceLocator)
                serviceLocator.pipeline().deliver(.report(events: [event]))
            }
        }
        container.resolve(function)
    }

    /// Set a user email to the Optimove SDK.
    ///
    /// - Parameter email: The user email.
    @objc public static func setUserEmail(email: String) {
        shared.setUserEmail(email: email)
    }

    private func _setUserEmail(_ email: String, _ serviceLocator: ServiceLocator) throws -> Event {
        return try serviceLocator.coreEventFactory().createEvent(.setUserEmail(email: email))
    }

    /// A call to this method will stop executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To continue receiving push campaigns after disabling,
    /// you have to call the `enablePushCampaigns` method.
    @objc public func disablePushCampaigns() {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            serviceLocator.pipeline().deliver(.togglePushCampaigns(areDisabled: true))
        }
        container.resolve(function)
    }

    /// A call to this method will stop executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To continue receiving push campaigns after disabling,
    /// you have to call the `enablePushCampaigns` method.
    @objc public static func disablePushCampaigns() {
        shared.disablePushCampaigns()
    }

    /// A call to this method will resume executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To stop receiving push campaigns after enabling,
    /// you have to call the `disablePushCampaigns` method.
    @objc public func enablePushCampaigns() {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            serviceLocator.pipeline().deliver(.togglePushCampaigns(areDisabled: false))
        }
        container.resolve(function)
    }

    /// A call to this method will resume executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To stop receiving push campaigns after enabling,
    /// you have to call the `disablePushCampaigns` method.
    @objc public static func enablePushCampaigns() {
        shared.enablePushCampaigns()
    }

}

// MARK: - Optimobile APIs

extension Optimove {

    /**
        Helper method for requesting the device token with alert, badge and sound permissions.

        On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
    */
    @objc public func pushRequestDeviceToken() {
        Optimobile.pushRequestDeviceToken()
    }

    /**
        Helper method for requesting the device token with alert, badge and sound permissions.

        On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
    */
    @available(iOS 10.0, *)
    @objc public func pushRequestDeviceToken(_ onAuthorizationStatus: OptimoveUNAuthorizationCheckedHandler? = nil) {
        Optimobile.pushRequestDeviceToken(onAuthorizationStatus)
    }

    /**
        Unsubscribe your device from the Kumulos Push service
    */
    @objc public func pushUnregister() {
        Optimobile.pushUnregister()
    }

    /**
        Register a device token with the Kumulos Push service.

        Note you shouldn't normally need to call this method.

        Parameters:
            - deviceToken: The push token returned by the device
    */
    @objc public func pushRegister(_ deviceToken: Data) {
        Optimobile.pushRegister(deviceToken)
    }

    /**
     Used for Deferred Deep Linking to pass the continuation to the Optimove SDK to be processed.
     */
    @objc public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return Optimobile.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    /**
     Used for Deferred Deep Linking to pass the continuation to the Optimove SDK to be processed in scene-based apps.
     */
    @available(iOS 13.0, *)
    @objc public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Optimobile.scene(scene, continue: userActivity)
    }
}

// MARK: - OptiPush API call

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

    /// Tells the Optimove SDK that a remote notification arrived that indicates there is data to be fetched.
    ///
    /// - Parameters:
    ///   - userInfo: A dictionary that contains information related to the remote notification.
    ///   - completionHandler: The block to execute when the download operation is complete.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public static func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        didComplete: @escaping (UIBackgroundFetchResult) -> Void
        ) -> Bool {
        return shared.didReceiveRemoteNotification(userInfo: userInfo, didComplete: didComplete)
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
        let function: (ServiceLocator) -> (Bool) = { serviceLocator in
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
        return container.resolve(function) ?? false
    }

    /// Asks the Optimove SDK how to handle a notification that arrived while the app was running in the foreground.
    ///
    /// - Parameters:
    ///   - notification: The notification that is about to be delivered.
    ///   - completionHandler: The block to execute when the download operation is complete.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public static func willPresent(
        notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) -> Bool {
        return shared.willPresent(notification: notification, withCompletionHandler: completionHandler)
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
        Logger.info("User produced the response for the notificaiton.")
        let function: (ServiceLocator) -> (Bool) = { serviceLocator in
            let notificationListener = serviceLocator.notificationListener()
            let result = notificationListener.isOptipush(notification: response.notification)
            if result {
                Optimove.shared.startSDK { result in
                    guard result.isSuccessful else { return }
                    notificationListener.didReceive(
                        response: response,
                        withCompletionHandler: completionHandler
                    )
                }
            }
            return result
        }
        return container.resolve(function) ?? false
    }

    /// Asks the Optimove SDK to process the user's response to a delivered notification.
    ///
    /// - Parameters:
    ///   - response: The user’s response to the notification.
    ///   - completionHandler: The block to execute when you have finished processing the user’s response.
    /// - Returns: Returns `true` if the Optimove SDK could handle a notification.
    @objc public static func didReceive(
        response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
        ) -> Bool {
        return shared.didReceive(response: response, withCompletionHandler: completionHandler)
    }

    /// Tells the Optimove SDK that the app successfully registered with Apple Push Notification service (APNs).
    ///
    /// - Parameter deviceToken: A token that was received from the AppDelegate.
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            let validationResult = APNsTokenValidator(storage: serviceLocator.storage())
            if validationResult.validate(token: deviceToken) == .new {
                Logger.debug("New APNS token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
                serviceLocator.pipeline().deliver(.deviceToken(token: deviceToken))
            }
        }
        container.resolve(function)
    }

    /// Tells the Optimove SDK that the app successfully registered with Apple Push Notification service (APNs).
    ///
    /// - Parameter deviceToken: A token that was received from the AppDelegate.
    @objc public static func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        shared.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// MARK: - OptimoveDeepLinkResponding

extension Optimove: OptimoveDeepLinkResponding {

    /// The subcription on a deeplink from a Optimove push notification.
    /// - Parameter responder: Subscriber
    @objc public func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        container.resolve { serviceLocator in
            serviceLocator.deeplinkService().register(deepLinkResponder: responder)
        }
    }

    /// The subcription on a deeplink from a Optimove push notification.
    /// - Parameter responder: Subscriber
    @objc public static func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        shared.register(deepLinkResponder: responder)
    }

    /// The unsubcription on a deeplink from a Optimove push notification.
    /// - Parameter responder: Subscriber
    @objc public func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        container.resolve { serviceLocator in
            serviceLocator.deeplinkService().unregister(deepLinkResponder: responder)
        }
    }

    /// The unsubcription on a deeplink from a Optimove push notification.
    /// - Parameter responder: Subscriber
    @objc public static func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        shared.unregister(deepLinkResponder: responder)
    }
}

// MARK: - Push notification channels

extension Optimove {

    /// The API provides an ability for the user to allow or disallow receiving specific push notifications.
    /// You can pass an array of permitted Push Notification channels for the current user.
    /// - Note: Pass `nil` to reset the current channel preferences and remove restrictions.
    /// - Parameter channels: Allowed channels names, case insensitive , or `nil`.
    @objc public static func setAllowedPushNotificationChannels(channels: Set<String>?) {
        shared.container.resolve { serviceLocator in
            serviceLocator.pipeline().deliver(.setPushNotificaitonChannels(channels: channels))
        }
    }

}

// MARK: - Private

private extension Optimove {

    // MARK: Initialization

    /// The method use to fetch tenant config, initialize Optimove SDK and control this process.
    /// - Parameter completion: A result of initializtion.
    func startSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            guard RunningFlagsIndication.isSdkNeedInitializing else {
                Logger.info("Skip initializtion since Optimove SDK already running.")
                completion(.success(()))
                return
            }
            RunningFlagsIndication.isInitializerRunning.toggle()
            serviceLocator.installationIdGenerator().generate()
            serviceLocator.firstTimeVisitGenerator().generate()
            let configurationFetcher = serviceLocator.configurationFetcher()
            configurationFetcher.fetch { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(configuration):
                    self.initialize(with: configuration)
                    Logger.info("Initialization finished. ✅")
                    completion(.success(()))
                case let .failure(error):
                    Logger.fatal("Initialization failed. 🛑\nReason: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        container.resolve(function)
    }

    // MARK: Configuration

    /// Initialization of SDK with a configuration.
    /// - Parameter configuration: A `Configuration` filetype.
    func initialize(with configuration: Configuration) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            let onStartEventGenerator = OnStartEventGenerator(
                coreEventFactory: serviceLocator.coreEventFactory(),
                synchronizer: serviceLocator.pipeline(),
                storage: serviceLocator.storage()
            )
            onStartEventGenerator.generate()
            let initializer = serviceLocator.initializer()
            initializer.initialize(with: configuration)
            RunningFlagsIndication.isInitializerRunning.toggle()
            RunningFlagsIndication.isSdkRunning.toggle()
        }
        container.resolve(function)
    }

}
