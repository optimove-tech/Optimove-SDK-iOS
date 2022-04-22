//
//  Kumulos.swift
//  Copyright © 2016 Kumulos. All rights reserved.
//

import Foundation
import UserNotifications

internal enum KumulosEvent : String {
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
public typealias PushOpenedHandlerBlock = (KSPushNotification) -> Void

@available(iOS 10.0, *)
public typealias PushReceivedInForegroundHandlerBlock = (KSPushNotification, (UNNotificationPresentationOptions)->Void) -> Void

public enum InAppConsentStrategy : String {
    case NotEnabled = "NotEnabled"
    case AutoEnroll = "AutoEnroll"
    case ExplicitByUser = "ExplicitByUser"
}

// MARK: class
open class Kumulos {
    internal let urlBuilder:UrlBuilder

    internal let pushHttpClient:KSHttpClient
    internal let coreHttpClient:KSHttpClient

    internal let pushNotificationDeviceType = 1
    internal let pushNotificationProductionTokenType:Int = 1

    internal let sdkVersion : String = "9.2.5"

    fileprivate static var instance:Kumulos?

    internal var notificationCenter:Any?

    internal static var sharedInstance:Kumulos {
        get {
            if(false == isInitialized()) {
                assertionFailure("The KumulosSDK has not been initialized")
            }

            return instance!
        }
    }

    public static func getInstance() -> Kumulos
    {
        return sharedInstance;
    }

    fileprivate(set) var config : OptimobileConfig
    fileprivate(set) var apiKey: String
    fileprivate(set) var secretKey: String
    fileprivate(set) var inAppConsentStrategy:InAppConsentStrategy = InAppConsentStrategy.NotEnabled

    internal static var inAppConsentStrategy : InAppConsentStrategy {
        get {
            return sharedInstance.inAppConsentStrategy
        }
    }

    fileprivate(set) var inAppHelper: InAppHelper

    fileprivate(set) var analyticsHelper: AnalyticsHelper
    fileprivate(set) var sessionHelper: SessionHelper
    fileprivate(set) var badgeObserver: KSBadgeObserver

    fileprivate var pushHelper: PushHelper

    fileprivate(set) var deepLinkHelper : DeepLinkHelper?

    public static var apiKey:String {
        get {
            return sharedInstance.apiKey
        }
    }

    public static var secretKey:String {
        get {
            return sharedInstance.secretKey
        }
    }

    /**
        The unique installation Id of the current app

        - Returns: String - UUID
    */
    public static var installId :String {
        get {
            return KumulosHelper.installId
        }
    }

    internal static func isInitialized() -> Bool {
        return instance != nil
    }

    /**
        Initialize the KumulosSDK.

        - Parameters:
              - config: An instance of KSConfig
    */
    internal static func initialize(config: OptimobileConfig) {
        if (instance !== nil) {
            assertionFailure("The KumulosSDK has already been initialized")
        }

        KeyValPersistenceHelper.maybeMigrateUserDefaultsToAppGroups()
        KeyValPersistenceHelper.set(config.apiKey, forKey: KumulosUserDefaultsKey.API_KEY.rawValue)
        KeyValPersistenceHelper.set(config.secretKey, forKey: KumulosUserDefaultsKey.SECRET_KEY.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.events], forKey: KumulosUserDefaultsKey.EVENTS_BASE_URL.rawValue)
        KeyValPersistenceHelper.set(config.baseUrlMap[.media], forKey: KumulosUserDefaultsKey.MEDIA_BASE_URL.rawValue)

        instance = Kumulos(config: config)

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
        badgeObserver = KSBadgeObserver(callback: { (newBadgeCount) in
           KeyValPersistenceHelper.set(newBadgeCount, forKey: KumulosUserDefaultsKey.BADGE_COUNT.rawValue)
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
