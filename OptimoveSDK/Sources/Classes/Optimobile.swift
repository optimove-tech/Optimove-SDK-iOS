//
//  ViewController.swift
//  Optimobile
//
//  Created by Barak Ben Hur on 04/04/2022.
//

import UIKit
import OptimoveCore
import CoreLocation

public class Optimobile {
    
    private static let internalQueue = DispatchQueue(label: "com.singletioninternal.queue",
                                                     qos: .default,
                                                     attributes: .concurrent)
    private static let _sheard = Optimobile()
    
    public static var sheard: Optimobile {
        get {
            return internalQueue.sync {
                _sheard
            }
        }
    }
    
    public typealias deepLinkComplition = (_ deepLinkResolution: DeepLinkResolution) -> ()
    public typealias inAppComplition = (_ deepLink: [AnyHashable : Any], _ message: NSDictionary?) -> ()
    public typealias pushOpenedComplition = (_ action: String? , _ data: [AnyHashable : Any]?) -> ()
    
    public enum Abilities {
        case deppLinking(responder: deepLinkComplition?),
             inApp(responder: inAppComplition?, inAppConsentStrategy: InAppConsentStrategy),
             pushOpened(responder: pushOpenedComplition?)
    }
    
    private static var builder: KSConfigBuilder!
    
    private init() {}
    
    public static func configure(for tenantInfo: OptimoveTenantInfo, apiKey: String, secretKey: String, abilities: [Abilities]? = nil) {
        Optimove.configure(for: tenantInfo)
        builder = KSConfigBuilder(apiKey: apiKey, secretKey: secretKey)
        if let abilities = abilities {
            for abilitie in abilities {
                switch abilitie {
                case .deppLinking(let responder):
                    registerDeepLink(deepLinkResponder: responder)
                case .inApp(responder: let responder, let inAppConsentStrategy):
                    registerInApp(inAppResponder: responder, inAppConsentStrategy: inAppConsentStrategy)
                case .pushOpened(responder: let responder):
                    registerPushOpenedHandler(inAppResponder: responder)
                }
            }
        }
        
        Kumulos.initialize(config: builder.build())
    }
    
    public static func registerUser(sdkId userID: String, email: String) {
        Optimove.shared.registerUser(sdkId: userID, email: email)
        Kumulos.associateUserWithInstall(userIdentifier: userID, attributes: [
            "email": email as AnyObject
        ])
    }
    
    public static func setUserId(_ userID: String) {
        Optimove.shared.setUserId(userID)
        Kumulos.associateUserWithInstall(userIdentifier: userID)
    }
    
    public static func setUserEmail(email: String) {
        Optimove.shared.setUserEmail(email: email)
        Kumulos.associateUserWithInstall(userIdentifier: email)
    }
    
    public static func reportEvent(name: String, parameters: [String: Any] = [:]) {
        Optimove.shared.reportEvent(name: name, parameters: parameters)
    }
    
    public static func reportEvent(_ event: OptimoveEvent) {
        Optimove.shared.reportEvent(event)
    }
    
    public static func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
        Optimove.shared.reportScreenVisit(screenTitle: title, screenCategory: category)
    }
    
    public static func disablePushCampaigns() {
        Kumulos.pushUnregister()
    }
    
    public static func enablePushCampaigns() {
        Kumulos.pushRequestDeviceToken()
    }
    
//    public static func sendLocationUpdate(location: CLLocation) {
//        Kumulos.sendLocationUpdate(location: location)
//    }
//
//    public static func sendiBeaconProximity(beacon: CLBeacon) {
//        Kumulos.sendiBeaconProximity(beacon: beacon)
//    }
    
    private static func registerDeepLink(deepLinkResponder responder: deepLinkComplition? = nil) {
        builder.enableDeepLinking({ (resolution) in
            responder?(resolution)
        })
    }
    
    private static func registerInApp(inAppResponder responder: inAppComplition? = nil, inAppConsentStrategy: InAppConsentStrategy) {
        builder.enableInAppMessaging(inAppConsentStrategy: inAppConsentStrategy).setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { buttonPress in
            let deepLink = buttonPress.deepLinkData
            let messageData = buttonPress.messageData
    
            responder?(deepLink, messageData)
        })
    }

    private static func registerPushOpenedHandler(inAppResponder responder: pushOpenedComplition? = nil) {
        builder.setPushOpenedHandler(pushOpenedHandlerBlock: { (notification : KSPushNotification) -> Void in
            if let action = notification.actionIdentifier {
                responder?(action, notification.data)
            } else {
                responder?(nil, nil)
            }
        })
    }
}
