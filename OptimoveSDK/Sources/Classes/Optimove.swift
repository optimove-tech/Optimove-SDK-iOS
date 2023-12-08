//  Copyright © 2017 Optimove. All rights reserved.

import CoreLocation
import OptimoveCore
import UIKit.UIApplication
import UserNotifications

typealias Logger = OptimoveCore.Logger

/// The Optimove SDK for iOS - a realtime customer data platform.
/// The integration guide: https://github.com/optimove-tech/Optimove-SDK-iOS/wiki
/// - WARNING:
///  To initialize and configure SDK using `Optimove.configure(for:)` first.
@objc public final class Optimove: NSObject {
    /// The current OptimoveSDK version string value.
    public static let version = OptimoveCore.SDKVersion

    /// The shared instance of Optimove SDK.
    @objc public static let shared: Optimove = .init()

    private let container: Container
    private var config: OptimoveConfig!

    override private init() {
        container = Assembly().makeContainer()
        container.resolve { serviceLocator in
            serviceLocator.loggerInitializator().initialize()
            serviceLocator.newVisitorIdGenerator().generate()
        }
        super.init()
    }

    /// The starting point of the Optimove SDK.
    static func configure(for config: OptimoveConfig) {
        /// FUTURE: To merge configure call with init.
        shared.container.resolve { serviceLocator in
            if let tenantInfo = config.tenantInfo {
                serviceLocator.newTenantInfoHandler().handle(tenantInfo)
            }
            serviceLocator.deviceStateObserver().start()
            shared.startSDK { _ in }
        }
    }

    public static func initialize(with config: OptimoveConfig) {
        shared.config = config

        if config.isOptimoveConfigured() {
            Optimove.configure(for: config)
        }

        if config.isOptimobileConfigured() {
            shared.container.resolve { serviceLocator in
                do {
                    let visitorId = try serviceLocator.storage().getInitialVisitorId()
                    let userId = try? serviceLocator.storage().getCustomerID()

                    try Optimobile.initialize(config: config, initialVisitorId: visitorId, initialUserId: userId)
                } catch {
                    throw GuardError.custom("Failed on OptimobileSDK initialization. Reason: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Set the credentials for the Optimove server. Intent to use as a step for the delayed initialization.
    public static func setCredentials(optimoveCredentials: String?, optimobileCredentials: String?) {
        guard let currentConfig = shared.config else {
            Logger.error("Optimove SDK is not configured yet. Please call Optimove.initialize(with:) first.")
            return
        }
        let builder = OptimoveConfigBuilder(from: currentConfig)
        builder.setCredentials(optimoveCredentials: optimoveCredentials, optimobileCredentials: optimobileCredentials)
        let config = builder.build()
        initialize(with: config)
    }

    public static func isFeatureRunning(_ feature: Feature) -> Bool {
        switch feature {
        case .optimobile:
            return Optimobile.isSdkRunning
        case .optimove:
            return RunningFlagsIndication.isSdkRunning
        default:
            return false
        }
    }
}

// MARK: - Event API call

public extension Optimove {
    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - parameters: The dictionary of attributes.
    @objc func reportEvent(name: String, parameters: [String: Any] = [:]) {
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
    @objc static func reportEvent(name: String, parameters: [String: Any] = [:]) {
        shared.reportEvent(name: name, parameters: parameters)
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc func reportEvent(_ event: OptimoveEvent) {
        container.resolve { serviceLocator in
            let tenantEvent = TenantEvent(name: event.name, context: event.parameters)
            serviceLocator.pipeline().deliver(.report(events: [tenantEvent]))
        }
    }

    /// Report the event to Optimove SDK.
    ///
    /// - Parameters:
    ///   - event: Instance of OptimoveEvent type.
    @objc static func reportEvent(_ event: OptimoveEvent) {
        shared.reportEvent(event)
    }
}

// MARK: - ScreenVisit API call

public extension Optimove {
    /// Report the screen visit event.
    /// - Parameters:
    ///   - screenTitle: The screen title.
    ///   - screenCategory: The screen category.
    @objc func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
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
    @objc static func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
        shared.reportScreenVisit(screenTitle: title, screenCategory: category)
    }
}

// MARK: - SetUserID API call

public extension Optimove {
    /// Set a user ID and a user email.
    ///
    /// - Parameters:
    ///   - sdkId: The user unique identifier.
    ///   - email: The user email.
    @objc func registerUser(sdkId userID: String, email: String) {
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
    @objc static func registerUser(sdkId userID: String, email: String) {
        shared.registerUser(sdkId: userID, email: email)
    }

    /// Set a user ID to the Optimove SDK.
    ///
    /// - Parameter userID: The user unique identifier.
    @objc func setUserId(_ userID: String) {
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
    @objc static func getVisitorID() -> String? {
        return shared.getVisitorID()
    }

    private func getVisitorID() -> String? {
        let function: (ServiceLocator) -> String? = { serviceLocator in
            try? serviceLocator.storage().getVisitorID()
        }
        guard let id = container.resolve(function) else { return nil }
        return id
    }

    /// Get the initial visitor identifier of Optimove SDK.
    @objc static func getInitialVisitorID() -> String? {
        return shared.getInitialVisitorID()
    }

    /// Get the initial visitor identifier of Optimove SDK.
    @objc func getInitialVisitorID() -> String? {
        let function: (ServiceLocator) -> String? = { serviceLocator in
            try? serviceLocator.storage().getInitialVisitorId()
        }
        guard let id = container.resolve(function) else { return nil }
        return id
    }

    /// Set a user ID to the Optimove SDK.
    ///
    /// - Parameter userID: The user unique identifier.
    @objc static func setUserId(_ userID: String) {
        shared.setUserId(userID)
    }

    private func _setUser(_ user: User, _ serviceLocator: ServiceLocator) throws -> Event {
        return try serviceLocator.coreEventFactory().createEvent(.setUser(user: user))
    }

    /// Set a user email to the Optimove SDK.
    ///
    /// - Parameter email: The user email.
    @objc func setUserEmail(email: String) {
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
    @objc static func setUserEmail(email: String) {
        shared.setUserEmail(email: email)
    }

    private func _setUserEmail(_ email: String, _ serviceLocator: ServiceLocator) throws -> Event {
        return try serviceLocator.coreEventFactory().createEvent(.setUserEmail(email: email))
    }

    /// Signout the user from the app
    ///  Call this function to unset the customerID and revert to an anonymous visitor
    @objc static func signOutUser() {
        shared.signOutUser()
    }

    /// Signout the user from the app
    /// Call this function to unset the customerID and revert to an anonymous visitor
    func signOutUser() {
        if config.isOptimoveConfigured() {
            let function: (ServiceLocator) -> Void = { serviceLocator in
                tryCatch {
                    serviceLocator.storage().set(value: nil, key: StorageKey.customerID)
                    serviceLocator.storage().set(value: serviceLocator.storage().initialVisitorId, key: StorageKey.visitorID)
                }
            }
            container.resolve(function)
        }

        if config.isOptimobileConfigured() {
            Optimobile.clearUserAssociation()
        }
    }
}

// MARK: - Optimobile APIs

public extension Optimove {
    /**
         Helper method for requesting the device token with alert, badge and sound permissions.

         On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
     */
    @objc func pushRequestDeviceToken() {
        Optimobile.pushRequestDeviceToken()
    }

    /**
         Helper method for requesting the device token with alert, badge and sound permissions.

         On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
     */
    @available(iOS 10.0, *)
    @objc func pushRequestDeviceToken(_ onAuthorizationStatus: OptimoveUNAuthorizationCheckedHandler? = nil) {
        Optimobile.pushRequestDeviceToken(onAuthorizationStatus)
    }

    /**
         Register a device token with the Optimove Push service.

         Note you shouldn't normally need to call this method, registration is handled by the SDK.

         Parameters:
             - deviceToken: The push token returned by the device
     */
    @objc func pushRegister(_ deviceToken: Data) {
        Optimobile.pushRegister(deviceToken)
    }

    /**
        Unregister the device token with the Optimove Push service.

        Notifications will no longer be received until pushRequestDeviceToken is called again
     */
    @objc func pushUnregister() {
        Optimobile.pushUnregister()
    }

    /**
        Used for Deferred Deep Linking to pass the continuation to the Optimove SDK to be processed.
     */
    @objc func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return Optimobile.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    /**
        Used for Deferred Deep Linking to pass the continuation to the Optimove SDK to be processed in scene-based apps.
     */
    @available(iOS 13.0, *)
    @objc func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Optimobile.scene(scene, continue: userActivity)
    }

    /**
         Updates the location of the current installation in Optimove. Accurate locaiton information is used for geofencing.
     */
    @objc func sendLocationUpdate(location: CLLocation) {
        Optimobile.sendLocationUpdate(location: location)
    }

    /**
         Records a proximity event for an iBeacon.
     */
    @objc func trackIBeaconProximity(beacon: CLBeacon) {
        Optimobile.trackIBeaconProximity(beacon: beacon)
    }

    /// Records a notification open event
    /// - Parameter userInfo - The userInfo dictionary you received in the push notification payload
    @objc func trackOpenMetric(userInfo: [AnyHashable: Any]) {
        Optimobile.pushTrackOpen(userInfo: userInfo)
    }

    /**
         Records a proximity event for an Eddystone beacon.
     */
    @objc func trackEddystoneBeaconProximity(hexNamespace: String, hexInstance: String, distanceMeters: NSNumber? = nil) {
        Optimobile.trackEddystoneBeaconProximity(hexNamespace: hexNamespace, hexInstance: hexInstance, distanceMeters: distanceMeters?.doubleValue)
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
                    RunningFlagsIndication.isInitializerRunning.toggle()
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
