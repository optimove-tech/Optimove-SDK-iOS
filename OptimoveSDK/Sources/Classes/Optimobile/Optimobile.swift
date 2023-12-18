//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UserNotifications

public typealias InAppDeepLinkHandlerBlock = (InAppButtonPress) -> Void
public typealias PushOpenedHandlerBlock = (PushNotification) -> Void

@available(iOS 10.0, *)
public typealias PushReceivedInForegroundHandlerBlock = (PushNotification, (UNNotificationPresentationOptions) -> Void) -> Void

public enum InAppConsentStrategy: String {
    case notEnabled = "NotEnabled"
    case autoEnroll = "AutoEnroll"
    case explicitByUser = "ExplicitByUser"
}

public enum InAppDisplayMode: String {
    case automatic
    case paused
}

final class Optimobile {
    enum Error: LocalizedError {
        case alreadyInitialized
        case configurationIsMissing
        case noCredentialsProvidedForDelayedConfigurationCompletion

        var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The OptimobileSDK has already been initialized."
            case .configurationIsMissing:
                return "OptimobileConfig is missing."
            case .noCredentialsProvidedForDelayedConfigurationCompletion:
                return "No OptimobileCredentials provided for delayed configuration completion."
            }
        }
    }

    let pushNotificationDeviceType = 1
    let pushNotificationProductionTokenType: Int = 1
    let sdkType: Int = 101
    fileprivate static var instance: Optimobile?
    var notificationCenter: Any?
    private(set) var config: OptimobileConfig
    private(set) var inAppConsentStrategy = InAppConsentStrategy.notEnabled
    private(set) var inAppManager: InAppManager
    private(set) var analyticsHelper: AnalyticsHelper
    private(set) var sessionHelper: SessionHelper
    private(set) var badgeObserver: OptimobileBadgeObserver
    private var pushHelper: PushHelper
    private(set) var deepLinkHelper: DeepLinkHelper?
    private let networkFactory: NetworkFactory
    private var credentials: OptimobileCredentials?
    let pendingNoticationHelper: PendingNotificationHelper
    let optimobileHelper: OptimobileHelper

    static var sharedInstance: Optimobile {
        if isInitialized() == false {
            assertionFailure("The OptimobileSDK has not been initialized")
        }

        return instance!
    }

    static func getInstance() -> Optimobile {
        return sharedInstance
    }

    static var inAppConsentStrategy: InAppConsentStrategy {
        return sharedInstance.inAppConsentStrategy
    }

    /**
         The unique installation Id of the current app

         - Returns: String - UUID
     */
    func installId() -> String {
        return optimobileHelper.installId()
    }

    static func isInitialized() -> Bool {
        return instance != nil
    }

    static var isSdkRunning: Bool {
        return Optimobile.instance?.credentials != nil
    }

    /**
         Initialize the Optimobile SDK.
     */
    static func initialize(
        optimoveConfig: OptimoveConfig,
        storage: OptimoveStorage
    ) throws {
        if instance !== nil, optimoveConfig.features.contains(.delayedConfiguration) {
            try completeDelayedConfiguration(config: optimoveConfig.optimobileConfig!, storage: storage)
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }

        guard let config = optimoveConfig.optimobileConfig else {
            throw Error.configurationIsMissing
        }

        try writeDefaultsKeys(config: config, storage: storage)

        instance = try Optimobile(config: config, storage: storage)

        instance!.initializeHelpers()

        if #available(iOS 10.0, *) {
            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                instance!.maybeTrackPushDismissedEvents()
            }
        }

        DispatchQueue.global().async {
            instance!.sendDeviceInformation(config: config)
        }

        instance!.maybeAlignUserAssociation(storage: storage)

        if !optimoveConfig.features.contains(.delayedConfiguration) {
            NotificationCenter.default.post(name: .optimobileInializationFinished, object: nil)
        }
    }

    static func completeDelayedConfiguration(config: OptimobileConfig, storage: OptimoveStorage) throws {
        guard let credentials = config.credentials else {
            throw Error.noCredentialsProvidedForDelayedConfigurationCompletion
        }
        Logger.info("Completing delayed configuration with credentials: \(credentials)")
        updateStorageValues(config, storage: storage)
        setCredentials(credentials)
        NotificationCenter.default.post(name: .optimobileInializationFinished, object: nil)
    }

    static func setCredentials(_ credentials: OptimobileCredentials) {
        Optimobile.instance?.credentials = credentials
    }

    static func updateStorageValues(_ config: OptimobileConfig, storage: OptimoveStorage) {
        storage.set(value: config.region.rawValue, key: .region)
        let baseUrlMap = UrlBuilder.defaultMapping(for: config.region.rawValue)
        storage.set(value: baseUrlMap[.media], key: .mediaURL)
    }

    fileprivate static func writeDefaultsKeys(
        config: OptimobileConfig,
        storage: OptimoveStorage
    ) throws {
        let existingInstallId: String? = storage[.installUUID]
        let initialVisitorId = try storage.getInitialVisitorId()
        // This block handles upgrades from Kumulos SDK users to Optimove SDK users
        // In the case where a user was auto-enrolled into in-app messaging on the K SDK, they would not become auto-enrolled
        // on the new Optimove SDK installation.
        //
        // To enable auto-enrollment on upgrade, we need to clear out the existing in-app consent key from storage when we detect
        // we're a new install. Note comparing to `nil` isn't enough because we may have a value depending if previous storage used
        // app groups or not.
        if existingInstallId != initialVisitorId,
           storage[.inAppConsented] != nil
        {
            storage.set(value: nil, key: .inAppConsented)
        }
        storage.set(value: initialVisitorId, key: .installUUID)

        if let credentials = config.credentials {
            setCredentials(credentials)
        }
        updateStorageValues(config, storage: storage)
    }

    fileprivate func maybeAlignUserAssociation(storage: OptimoveStorage) {
        guard let initialUserId: String = storage[.customerID] else {
            return
        }

        let optimobileUserId = optimobileHelper.currentUserIdentifier()
        if optimobileUserId == initialUserId {
            return
        }

        Optimobile.associateUserWithInstall(userIdentifier: initialUserId, storage: storage)
    }

    private init(config: OptimobileConfig, storage: OptimoveStorage) throws {
        self.config = config
        let urlBuilder = UrlBuilder(storage: storage)
        networkFactory = NetworkFactory(
            urlBuilder: urlBuilder,
            authorization: AuthorizationMediator(provider: {
                Optimobile.instance?.credentials
            })
        )
        inAppConsentStrategy = config.inAppConsentStrategy
        optimobileHelper = OptimobileHelper(
            storage: storage
        )
        analyticsHelper = try AnalyticsHelper(
            httpClient: networkFactory.build(for: .events),
            optimobileHelper: optimobileHelper,
            container: PersistentContainer(
                persistentContainerConfigurator: AnalyticsPersistentContainerConfigurator()
            )
        )

        sessionHelper = SessionHelper(sessionIdleTimeout: config.sessionIdleTimeout)
        pendingNoticationHelper = PendingNotificationHelper(
            storage: storage
        )
        inAppManager = try InAppManager(
            config,
            httpClient: networkFactory.build(for: .push),
            urlBuilder: urlBuilder,
            storage: storage,
            pendingNoticationHelper: pendingNoticationHelper,
            optimobileHelper: optimobileHelper,
            container: PersistentContainer(
                persistentContainerConfigurator: InAppPersistentContainerConfigurator()
            )
        )
        pushHelper = PushHelper(
            optimobileHelper: optimobileHelper
        )
        badgeObserver = OptimobileBadgeObserver(callback: { newBadgeCount in
            storage.set(value: newBadgeCount, key: .badgeCount)
        })

        if config.deepLinkHandler != nil {
            deepLinkHelper = DeepLinkHelper(
                config,
                httpClient: networkFactory.build(for: .ddl),
                storage: storage
            )
        }

        Logger.debug("Optimobile SDK was initialized with \(config)")
    }

    private func initializeHelpers() {
        sessionHelper.initialize()
        _ = pushHelper.pushInit
        deepLinkHelper?.checkForNonContinuationLinkMatch()
    }
}
