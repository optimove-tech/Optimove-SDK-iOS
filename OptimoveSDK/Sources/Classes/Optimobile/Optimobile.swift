//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UserNotifications

public typealias InAppDeepLinkHandlerBlock = (InAppButtonPress) -> Void
public typealias PushOpenedHandlerBlock = (PushNotification) -> Void

@available(iOS 10.0, *)
public typealias PushReceivedInForegroundHandlerBlock = (PushNotification, (UNNotificationPresentationOptions)->Void) -> Void

public enum InAppConsentStrategy : String {
    case notEnabled = "NotEnabled"
    case autoEnroll = "AutoEnroll"
    case explicitByUser = "ExplicitByUser"
}

public enum InAppDisplayMode : String {
    case automatic = "automatic"
    case paused = "paused"
}

// MARK: class
class Optimobile {
    let urlBuilder:UrlBuilder

    let pushHttpClient:KSHttpClient
    let coreHttpClient:KSHttpClient

    let pushNotificationDeviceType = 1
    let pushNotificationProductionTokenType:Int = 1

    let sdkType : Int = 101;

    fileprivate static var instance:Optimobile?

    var notificationCenter:Any?

    static var sharedInstance:Optimobile {
        get {
            if(false == isInitialized()) {
                assertionFailure("The OptimobileSDK has not been initialized")
            }

            return instance!
        }
    }

    static func getInstance() -> Optimobile
    {
        return sharedInstance;
    }

    fileprivate(set) var config : OptimobileConfig
    fileprivate(set) var apiKey: String
    fileprivate(set) var secretKey: String
    fileprivate(set) var inAppConsentStrategy:InAppConsentStrategy = InAppConsentStrategy.notEnabled

    static var inAppConsentStrategy : InAppConsentStrategy {
        get {
            return sharedInstance.inAppConsentStrategy
        }
    }

    fileprivate(set) var inAppManager: InAppManager

    fileprivate(set) var analyticsHelper: AnalyticsHelper
    fileprivate(set) var sessionHelper: SessionHelper
    fileprivate(set) var badgeObserver: OptimobileBadgeObserver

    fileprivate var pushHelper: PushHelper

    fileprivate(set) var deepLinkHelper : DeepLinkHelper?

    static var apiKey:String {
        get {
            return sharedInstance.apiKey
        }
    }

    static var secretKey:String {
        get {
            return sharedInstance.secretKey
        }
    }

    /**
        The unique installation Id of the current app

        - Returns: String - UUID
    */
    static var installId :String {
        get {
            return OptimobileHelper.installId
        }
    }

    static func isInitialized() -> Bool {
        return instance != nil
    }

    /**
        Initialize the Optimobile SDK.
    */
    static func initialize(config: OptimobileConfig, initialVisitorId: String, initialUserId: String?) {
        if (instance !== nil) {
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
        
        
        let existingInstallId = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue) as? String;
        // This block handles upgrades from Kumulos SDK users to Optimove SDK users
        // In the case where a user was auto-enrolled into in-app messaging on the K SDK, they would not become auto-enrolled
        // on the new Optimove SDK installation.
        //
        // To enable auto-enrollment on upgrade, we need to clear out the existing in-app consent key from storage when we detect
        // we're a new install. Note comparing to `nil` isn't enough because we may have a value depending if previous storage used
        // app groups or not.
        if existingInstallId != initialVisitorId,
           let _ = UserDefaults.standard.object(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue) {
            UserDefaults.standard.removeObject(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
        }

        KeyValPersistenceHelper.set(config.apiKey, forKey: OptimobileUserDefaultsKey.API_KEY.rawValue)
        KeyValPersistenceHelper.set(config.secretKey, forKey: OptimobileUserDefaultsKey.SECRET_KEY.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.events], forKey: OptimobileUserDefaultsKey.EVENTS_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.media], forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(initialVisitorId, forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue)
    }

    fileprivate static func maybeAlignUserAssociation(initialUserId: String?) {
        if (initialUserId == nil) {
            return
        }

        let optimobileUserId = OptimobileHelper.currentUserIdentifier
        if (optimobileUserId == initialUserId) {
            return
        }

        Optimobile.associateUserWithInstall(userIdentifier: initialUserId!)
    }

    fileprivate init(config: OptimobileConfig) {
        self.config = config
        apiKey = config.apiKey
        secretKey = config.secretKey
        inAppConsentStrategy = config.inAppConsentStrategy

        urlBuilder = UrlBuilder(baseUrlMap: config.baseUrlMap)

        pushHttpClient = KSHttpClient(baseUrl: URL(string: urlBuilder.urlForService(.push))!, requestFormat: .json, responseFormat: .json)
        pushHttpClient.setBasicAuth(user: config.apiKey, password: config.secretKey)
        coreHttpClient = KSHttpClient(baseUrl: URL(string: urlBuilder.urlForService(.crm))!, requestFormat: .json, responseFormat: .json)
        coreHttpClient.setBasicAuth(user: config.apiKey, password: config.secretKey)

        analyticsHelper = AnalyticsHelper(apiKey: apiKey, secretKey: secretKey, baseEventsUrl: urlBuilder.urlForService(.events))
        sessionHelper = SessionHelper(sessionIdleTimeout: config.sessionIdleTimeout)
        inAppManager = InAppManager(config)
        pushHelper = PushHelper()
        badgeObserver = OptimobileBadgeObserver(callback: { (newBadgeCount) in
           KeyValPersistenceHelper.set(newBadgeCount, forKey: OptimobileUserDefaultsKey.BADGE_COUNT.rawValue)
        })

        if config.deepLinkHandler != nil {
            deepLinkHelper = DeepLinkHelper(config, urlBuilder: urlBuilder)
        }
    }

    private func initializeHelpers() {
        sessionHelper.initialize()
        inAppManager.initialize()
        _ = pushHelper.pushInit
        deepLinkHelper?.checkForNonContinuationLinkMatch()
    }

    deinit {
        pushHttpClient.invalidateSessionCancellingTasks(true)
        coreHttpClient.invalidateSessionCancellingTasks(true)
    }

}
