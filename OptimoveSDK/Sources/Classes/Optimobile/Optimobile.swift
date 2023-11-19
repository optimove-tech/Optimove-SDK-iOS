//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
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

class Optimobile {
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

    fileprivate(set) var config: OptimobileConfig
    fileprivate(set) var inAppConsentStrategy = InAppConsentStrategy.notEnabled

    static var inAppConsentStrategy: InAppConsentStrategy {
        return sharedInstance.inAppConsentStrategy
    }

    fileprivate(set) var inAppManager: InAppManager

    fileprivate(set) var analyticsHelper: AnalyticsHelper
    fileprivate(set) var sessionHelper: SessionHelper
    fileprivate(set) var badgeObserver: OptimobileBadgeObserver

    fileprivate var pushHelper: PushHelper

    fileprivate(set) var deepLinkHelper: DeepLinkHelper?

    private let networkFactory: NetworkFactory

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

    /**
         Initialize the Optimobile SDK.
     */
    static func initialize(config: OptimobileConfig, initialVisitorId: String, initialUserId: String?) {
        if instance !== nil {
            assertionFailure("The OptimobileSDK has already been initialized")
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

        KeyValPersistenceHelper.set(config.region.rawValue, forKey: OptimobileUserDefaultsKey.REGION.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.media], forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.iar], forKey: OptimobileUserDefaultsKey.IAR_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(initialVisitorId, forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue)
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

    fileprivate init(config: OptimobileConfig) {
        self.config = config
        networkFactory = NetworkFactory(
            urlBuilder: UrlBuilder(baseUrlMap: config.baseUrlMap),
            authorization: AuthorizationMediator(storage: KeyValPersistenceHelper.self)
        )
        inAppConsentStrategy = config.inAppConsentStrategy

        analyticsHelper = AnalyticsHelper(httpClient: networkFactory.build(for: .events))

        sessionHelper = SessionHelper(sessionIdleTimeout: config.sessionIdleTimeout)
        inAppManager = InAppManager(config, httpClient: networkFactory.build(for: .push))
        pushHelper = PushHelper()
        badgeObserver = OptimobileBadgeObserver(callback: { newBadgeCount in
            KeyValPersistenceHelper.set(newBadgeCount, forKey: OptimobileUserDefaultsKey.BADGE_COUNT.rawValue)
        })

        if config.deepLinkHandler != nil {
            deepLinkHelper = DeepLinkHelper(config, httpClient: networkFactory.build(for: .ddl))
        }
    }

    private func initializeHelpers() {
        sessionHelper.initialize()
        inAppManager.initialize()
        _ = pushHelper.pushInit
        deepLinkHelper?.checkForNonContinuationLinkMatch()
    }
}
