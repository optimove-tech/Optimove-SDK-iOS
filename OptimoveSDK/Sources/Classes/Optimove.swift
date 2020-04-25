//  Copyright © 2017 Optimove. All rights reserved.

import UIKit.UIApplication
import UserNotifications
import OptimoveCore

public typealias Event = OptimoveCore.Event

/// The Optimove SDK for iOS - a realtime customer data platform.
/// The integration guide: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki
/// - WARNING:
///  To initialize and configure SDK using `Optimove.configure(for:)` first.
@objc public final class Optimove: NSObject {

    /// The current OptimoveSDK version string value.
    public static let version = SDKVersion

    /// The shared instance of Optimove SDK.
    @objc public static let shared: Optimove = {
        return Optimove()
    }()

    private let container: Container

    private override init() {
        self.container = Assembly().makeContainer()
        super.init()
    }

    /// The starting point of the Optimove SDK.
    ///
    /// - Parameter tenantInfo: Basic client information received on the onboarding process with Optimove.
    @objc public static func configure(for tenantInfo: OptimoveTenantInfo) {
        /// FUTURE: To merge configure call with init.
        shared.container.resolve { serviceLocator in
            serviceLocator.loggerInitializator().initialize()
            serviceLocator.newTenantInfoHandler().handle(tenantInfo)
            serviceLocator.deviceStateObserver().start()
            shared.startSDK { _ in }
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
            serviceLocator.synchronizer().handle(.report(event: tenantEvent))
        }
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc public func reportEvent(_ event: OptimoveEvent) {
        container.resolve { serviceLocator in
            let tenantEvent = TenantEvent(name: event.name, context: event.parameters)
            serviceLocator.synchronizer().handle(.report(event: tenantEvent))
        }
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
        Logger.debug("Report a screen event with title: \(title) and category \(category ?? "nil")")
        let validationResult = ScreenVisitValidator.validate(screenTitle: title)
        guard validationResult == .valid else { return }
        container.resolve { serviceLocator in
            tryCatch {
                let factory = serviceLocator.coreEventFactory()
                try factory.createEvent(.pageVisit(title: title, category: category)) { event in
                    serviceLocator.synchronizer().handle(.report(event: event))
                }
            }
        }
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
        let function: (ServiceLocator) -> Void = { serviceLocator in
            let storage = serviceLocator.storage()
            let validationResult = UserIDValidator(storage: storage).validateNewUserID(userID)
            guard validationResult == .valid else { return }
            NewUserIDHandler(storage: storage).handle(userID: userID)
            tryCatch {
                try serviceLocator.coreEventFactory().createEvent(.setUserId) { event in
                    serviceLocator.synchronizer().handle(.report(event: event))
                    serviceLocator.synchronizer().handle(.setInstallation)
                }
            }
        }
        container.resolve(function)
    }

    /// Set a user email to the Optimove SDK.
    ///
    /// - Parameter email: The user email.
    @objc public func setUserEmail(email: String) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            let storage = serviceLocator.storage()
            let validationResult = EmailValidator(storage: storage).isValid(email)
            guard validationResult == .valid else { return }
            NewEmailHandler(storage: storage).handle(email: email)
            tryCatch {
                try serviceLocator.coreEventFactory().createEvent(.setUserEmail) { event in
                    serviceLocator.synchronizer().handle(.report(event: event))
                }
            }
        }
        container.resolve(function)
    }

    /// A call to this method will stop executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To continue receiving push campaigns after disabling,
    /// you have to call the `enablePushCampaigns` method.
    @objc public func disablePushCampaigns() {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            serviceLocator.synchronizer().handle(.togglePushCampaigns(areDisabled: true))
        }
        container.resolve(function)
    }

    /// A call to this method will resume executions of any push campaign
    /// targeted to this installation.
    /// By default, receiving a push campaign is enabled.
    /// To stop receiving push campaigns after enabling,
    /// you have to call the `disablePushCampaigns` method.
    @objc public func enablePushCampaigns() {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            serviceLocator.synchronizer().handle(.togglePushCampaigns(areDisabled: false))
        }
        container.resolve(function)
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

    /// Tells the Optimove SDK that the app successfully registered with Apple Push Notification service (APNs).
    ///
    /// - Parameter deviceToken: A token that was received from the AppDelegate.
    @objc public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            let validationResult = APNsTokenValidator(storage: serviceLocator.storage())
            if validationResult.validate(token: deviceToken) == .new {
                Logger.debug("New APNS token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
                serviceLocator.synchronizer().handle(.deviceToken(token: deviceToken))
            }
        }
        container.resolve(function)
    }

    /// User authorization is required for applications to notify the user using UNUserNotificationCenter via both local and remote notifications.
    ///
    /// - Parameter fromUserNotificationCenter: A response from
    @objc public func didReceivePushAuthorization(fromUserNotificationCenter granted: Bool) {
        let function: (ServiceLocator) -> Void = { serviceLocator in
            tryCatch {
                try serviceLocator.optInService().didPushAuthorization(isGranted: granted)
            }
        }
        container.resolve(function)
    }

}

// MARK: - OptimoveDeepLinkResponding

extension Optimove: OptimoveDeepLinkResponding {

    @objc public func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        container.resolve { serviceLocator in
            serviceLocator.deeplinkService().register(deepLinkResponder: responder)
        }
    }

    @objc public func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        container.resolve { serviceLocator in
            serviceLocator.deeplinkService().unregister(deepLinkResponder: responder)
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
            serviceLocator.newVisitorIdGenerator().generate()
            serviceLocator.firstTimeVisitGenerator().generate()
            let configurationFetcher = serviceLocator.configurationFetcher()
            configurationFetcher.fetch { result in
                switch result {
                case let .success(configuration):
                    self.initialize(with: configuration)
                    Logger.info("Initialization finished. ✅")
                    completion(.success(()))
                case let .failure(error):
                    Logger.error("Initialization failed. 🛑\nReason: \(error.localizedDescription)")
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
                synchronizer: serviceLocator.synchronizer(),
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

// MARK: - Deprecated

extension Optimove {

    /// Request to subscribe to test campaign topics
    @available(*, deprecated, message: "No need to calls start test mode. Use Optimove site for tests.")
    @objc public func startTestMode() {}

    /// Request to unsubscribe from test campaign topics
    @available(*, deprecated, message: "No need to calls stop test mode. Use Optimove site for tests.")
    @objc public func stopTestMode() {}

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenPathArray: An array of breadcrumbs – an UI path to the screen.
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @available(*, deprecated, renamed: "reportScreenVisit(screenTitle:screenCategory:)")
    @objc public func setScreenVisit(screenPathArray: [String], screenTitle: String, screenCategory: String? = nil) {
        reportScreenVisit(screenTitle: screenTitle, screenCategory: screenCategory)
    }

    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenPath: An UI path to the screen.
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @available(*, deprecated, renamed: "reportScreenVisit(screenTitle:screenCategory:)")
    @objc public func setScreenVisit(screenPath: String,
                                     screenTitle: String,
                                     screenCategory: String? = nil) {
            reportScreenVisit(screenTitle: screenTitle, screenCategory: screenCategory)
    }

}
