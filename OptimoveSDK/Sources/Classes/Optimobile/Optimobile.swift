//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UserNotifications

internal enum OptimobileEvent : String {
    case STATS_FOREGROUND = "k.fg"
    case STATS_BACKGROUND = "k.bg"
    case STATS_CALL_HOME = "k.stats.installTracked"
    case STATS_ASSOCIATE_USER = "k.stats.userAssociated"
    case STATS_USER_ASSOCIATION_CLEARED = "k.stats.userAssociationCleared"
    case PUSH_DEVICE_REGISTER = "k.push.deviceRegistered"
    case ENGAGE_BEACON_ENTERED_PROXIMITY = "k.engage.beaconEnteredProximity"
    case ENGAGE_LOCATION_UPDATED = "k.engage.locationUpdated"
    case DEVICE_UNSUBSCRIBED = "k.push.deviceUnsubscribed"
    case IN_APP_CONSENT_CHANGED = "k.inApp.statusUpdated"
    case MESSAGE_OPENED = "k.message.opened"
    case MESSAGE_DISMISSED = "k.message.dismissed"
    case MESSAGE_DELETED_FROM_INBOX = "k.message.inbox.deleted"
    case DEEP_LINK_MATCHED = "k.deepLink.matched"
    case MESSAGE_READ = "k.message.read"
}

public typealias InAppDeepLinkHandlerBlock = (InAppButtonPress) -> Void
public typealias PushOpenedHandlerBlock = (PushNotification) -> Void

@available(iOS 10.0, *)
public typealias PushReceivedInForegroundHandlerBlock = (PushNotification, (UNNotificationPresentationOptions)->Void) -> Void

public enum InAppConsentStrategy : String {
    case NotEnabled = "NotEnabled"
    case AutoEnroll = "AutoEnroll"
    case ExplicitByUser = "ExplicitByUser"
}

// MARK: class
class Optimobile {
    let urlBuilder:UrlBuilder

    let pushHttpClient:KSHttpClient
    let coreHttpClient:KSHttpClient

    let pushNotificationDeviceType = 1
    let pushNotificationProductionTokenType:Int = 1

    let sdkVersion : String = "4.0.0"
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
    fileprivate(set) var inAppConsentStrategy:InAppConsentStrategy = InAppConsentStrategy.NotEnabled

    static var inAppConsentStrategy : InAppConsentStrategy {
        get {
            return sharedInstance.inAppConsentStrategy
        }
    }

    fileprivate(set) var inAppHelper: InAppHelper

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
        Initialize the KumulosSDK.

        - Parameters:
              - config: An instance of KSConfig
    */
    static func initialize(config: OptimobileConfig, initialVisitorId: String) {
        if (instance !== nil) {
            assertionFailure("The OptimobileSDK has already been initialized")
        }

        KeyValPersistenceHelper.maybeMigrateUserDefaultsToAppGroups()
        KeyValPersistenceHelper.set(config.apiKey, forKey: OptimobileUserDefaultsKey.API_KEY.rawValue)
        KeyValPersistenceHelper.set(config.secretKey, forKey: OptimobileUserDefaultsKey.SECRET_KEY.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.events], forKey: OptimobileUserDefaultsKey.EVENTS_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.media], forKey: OptimobileUserDefaultsKey.MEDIA_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(initialVisitorId, forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue)

        instance = Optimobile(config: config)

        instance!.initializeHelpers()

        if #available(iOS 10.0, *) {
            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                instance!.maybeTrackPushDismissedEvents()
            }
        }

        DispatchQueue.global().async {
            instance!.sendDeviceInformation()
        }
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
        inAppHelper = InAppHelper()
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
        inAppHelper.initialize()
        _ = pushHelper.pushInit
        deepLinkHelper?.checkForNonContinuationLinkMatch()
    }

    deinit {
        pushHttpClient.invalidateSessionCancellingTasks(true)
        coreHttpClient.invalidateSessionCancellingTasks(true)
    }

}
