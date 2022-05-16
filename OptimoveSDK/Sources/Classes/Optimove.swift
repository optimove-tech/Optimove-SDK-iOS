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
    
    @objc public static var initialized: Bool = false

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
    
    public static func initialize(with config: OptimoveConfig, state: ((_ otimove: Bool, _ optimobile: Bool) -> ())? = nil) {
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
            
            state?(Optimove.initialized ,Optimobile.isInitialized())
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
        Unsubscribe your device from the Optimove Push service
    */
    @objc public func pushUnregister() {
        Optimobile.pushUnregister()
    }

    /**
        Register a device token with the Optimove Push service.

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
                    Optimove.initialized = true
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
