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

// MARK: class

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

    static var sharedInstance: Optimobile {
        if isInitialized() == false {
            assertionFailure("The OptimobileSDK has not been initialized")
        }

        return instance!
    }

    static func getInstance() -> Optimobile {
        return sharedInstance
    }

    private(set) var config: OptimobileConfig
    private(set) var inAppConsentStrategy = InAppConsentStrategy.notEnabled

    static var inAppConsentStrategy: InAppConsentStrategy {
        return sharedInstance.inAppConsentStrategy
    }

    private(set) var inAppManager: InAppManager

    private(set) var analyticsHelper: AnalyticsHelper
    private(set) var sessionHelper: SessionHelper
    private(set) var badgeObserver: OptimobileBadgeObserver

    private var pushHelper: PushHelper

    private(set) var deepLinkHelper: DeepLinkHelper?

    private let networkFactory: NetworkFactory
    private var credentials: OptimobileCredentials?

    /**
         The unique installation Id of the current app

         - Returns: String - UUID
     */
    static var installId: String {
        return OptimobileHelper.installId
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
    static func initialize(config optimoveConfig: OptimoveConfig, initialVisitorId: String, initialUserId: String?) throws {
        if instance !== nil, optimoveConfig.features.contains(.delayedConfiguration) {
            try completeDelayedConfiguration(config: optimoveConfig.optimobileConfig!)
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }

        guard let config = optimoveConfig.optimobileConfig else {
            throw Error.configurationIsMissing
        }

        writeDefaultsKeys(config: config, initialVisitorId: initialVisitorId)

        instance = Optimobile(config: config)

        instance!.initializeHelpers()

        if #available(iOS 10.0, *) {
            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                instance!.maybeTrackPushDismissedEvents()
            }
        }

        DispatchQueue.global().async {
            instance!.sendDeviceInformation(config: config)
        }

        maybeAlignUserAssociation(initialUserId: initialUserId)

        if !optimoveConfig.features.contains(.delayedConfiguration) {
            NotificationCenter.default.post(name: .optimobileInializationFinished, object: nil)
        }
    }

    static func completeDelayedConfiguration(config: OptimobileConfig) throws {
        guard let credentials = config.credentials else {
            throw Error.noCredentialsProvidedForDelayedConfigurationCompletion
        }
        Logger.info("Completing delayed configuration with credentials: \(credentials)")
        updateStorageValues(config)
        setCredentials(credentials)
        NotificationCenter.default.post(name: .optimobileInializationFinished, object: nil)
    }

    static func setCredentials(_ credentials: OptimobileCredentials) {
        Optimobile.instance?.credentials = credentials
    }

    static func updateStorageValues(_ config: OptimobileConfig) {
        KeyValPersistenceHelper.set(config.region.rawValue, forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        let baseUrlMap = UrlBuilder.defaultMapping(for: config.region.rawValue)
        KeyValPersistenceHelper.set(baseUrlMap[.media], forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
    }

    fileprivate static func writeDefaultsKeys(config: OptimobileConfig, initialVisitorId: String) {
        KeyValPersistenceHelper.maybeMigrateUserDefaultsToAppGroups()

        let existingInstallId = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue) as? String
        // This block handles upgrades from Kumulos SDK users to Optimove SDK users
        // In the case where a user was auto-enrolled into in-app messaging on the K SDK, they would not become auto-enrolled
        // on the new Optimove SDK installation.
        //
        // To enable auto-enrollment on upgrade, we need to clear out the existing in-app consent key from storage when we detect
        // we're a new install. Note comparing to `nil` isn't enough because we may have a value depending if previous storage used
        // app groups or not.
        if existingInstallId != initialVisitorId,
           let _ = UserDefaults.standard.object(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
        {
            UserDefaults.standard.removeObject(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
        }
        KeyValPersistenceHelper.set(initialVisitorId, forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue)

        if let credentials = config.credentials {
            setCredentials(credentials)
        }
        updateStorageValues(config)
    }

    fileprivate static func maybeAlignUserAssociation(initialUserId: String?) {
        if initialUserId == nil {
            return
        }

        let optimobileUserId = OptimobileHelper.currentUserIdentifier
        if optimobileUserId == initialUserId {
            return
        }

        Optimobile.associateUserWithInstall(userIdentifier: initialUserId!)
    }

    private init(config: OptimobileConfig) {
        self.config = config
        let urlBuilder = UrlBuilder(storage: KeyValPersistenceHelper.self)
        networkFactory = NetworkFactory(
            urlBuilder: urlBuilder,
            authorization: AuthorizationMediator(provider: {
                Optimobile.instance?.credentials
            })
        )
        inAppConsentStrategy = config.inAppConsentStrategy

        analyticsHelper = AnalyticsHelper(
            httpClient: networkFactory.build(for: .events)
        )

        sessionHelper = SessionHelper(sessionIdleTimeout: config.sessionIdleTimeout)
        inAppManager = InAppManager(config, httpClient: networkFactory.build(for: .push), urlBuilder: urlBuilder)
        pushHelper = PushHelper()
        badgeObserver = OptimobileBadgeObserver(callback: { newBadgeCount in
            KeyValPersistenceHelper.set(newBadgeCount, forKey: OptimobileUserDefaultsKey.BADGE_COUNT.rawValue)
        })

        if config.deepLinkHandler != nil {
            deepLinkHelper = DeepLinkHelper(config, httpClient: networkFactory.build(for: .ddl))
        }

        Logger.debug("Optimobile SDK was initialized with \(config)")
    }

    private func initializeHelpers() {
        sessionHelper.initialize()
        inAppManager.initialize()
        _ = pushHelper.pushInit
        deepLinkHelper?.checkForNonContinuationLinkMatch()
    }
}
