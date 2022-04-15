// Copyright © 2022 Optimove. All rights reserved.

import UIKit
import OptimoveCore
import CoreLocation

public class Optimobile {
    
    private static let internalQueue = DispatchQueue(label: "com.singletioninternal.queue",
                                                     qos: .default,
                                                     attributes: .concurrent)
    private static let _shared = Optimobile()
    
    public static var shared: Optimobile {
        get {
            return internalQueue.sync {
                _shared
            }
        }
    }
    
    public typealias deepLinkCompletion = (_ deepLinkResolution: DeepLinkResolution) -> ()
    public typealias inAppCompletion = (_ deepLink: [AnyHashable : Any], _ message: NSDictionary?) -> ()
    public typealias pushOpenedCompletion = (_ action: String? , _ data: [AnyHashable : Any]?) -> ()
    
    public enum Abilities {
        case deepLinking(responder: deepLinkCompletion?),
             inApp(responder: inAppCompletion?, inAppConsentStrategy: InAppConsentStrategy),
             pushOpened(responder: pushOpenedCompletion?)
    }
    
    private var builder: ConfigBuilder!
    
    private init() {}
    
    public func configure(for tenantInfo: OptimoveTenantInfo, region: String, apiKey: String, secretKey: String, abilities: [Abilities]? = nil) {
        Optimove.configure(for: tenantInfo)
        builder = ConfigBuilder(region: region, apiKey: apiKey, secretKey: secretKey)
        if let abilities = abilities {
            for abilitie in abilities {
                switch abilitie {
                case .deepLinking(let responder):
                    registerDeepLink(deepLinkResponder: responder)
                case .inApp(responder: let responder, let inAppConsentStrategy):
                    registerInApp(inAppResponder: responder, inAppConsentStrategy: inAppConsentStrategy)
                case .pushOpened(responder: let responder):
                    registerPushOpenedHandler(inAppResponder: responder)
                }
            }
        }
        
        OptiMobile.initialize(config: builder.build())
    }
    
    public func registerUser(sdkId userID: String, email: String) {
        Optimove.shared.registerUser(sdkId: userID, email: email)
        OptiMobile.associateUserWithInstall(userIdentifier: userID, attributes: [
            "email": email as AnyObject
        ])
    }
    
    public func setUserId(_ userID: String) {
        Optimove.shared.setUserId(userID)
        OptiMobile.associateUserWithInstall(userIdentifier: userID)
    }
    
    public func setUserEmail(email: String) {
        Optimove.shared.setUserEmail(email: email)
        OptiMobile.associateUserWithInstall(userIdentifier: email)
    }
    
    public func reportEvent(name: String, parameters: [String: Any] = [:]) {
        Optimove.shared.reportEvent(name: name, parameters: parameters)
    }
    
    public func reportEvent(_ event: OptimoveEvent) {
        Optimove.shared.reportEvent(event)
    }
    
    public func reportScreenVisit(screenTitle title: String, screenCategory category: String? = nil) {
        Optimove.shared.reportScreenVisit(screenTitle: title, screenCategory: category)
    }
    
    public func disablePushCampaigns() {
        OptiMobile.pushUnregister()
    }
    
    public func enablePushCampaigns() {
        OptiMobile.pushRequestDeviceToken()
    }
    
//    public static func sendLocationUpdate(location: CLLocation) {
//        Kumulos.sendLocationUpdate(location: location)
//    }
//
//    public static func sendiBeaconProximity(beacon: CLBeacon) {
//        Kumulos.sendiBeaconProximity(beacon: beacon)
//    }
    
    private func registerDeepLink(deepLinkResponder responder: deepLinkCompletion? = nil) {
        builder.enableDeepLinking({ (resolution) in
            responder?(resolution)
        })
    }
    
    private func registerInApp(inAppResponder responder: inAppCompletion? = nil, inAppConsentStrategy: InAppConsentStrategy) {
        builder.enableInAppMessaging(inAppConsentStrategy: inAppConsentStrategy).setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { buttonPress in
            let deepLink = buttonPress.deepLinkData
            let messageData = buttonPress.messageData
    
            responder?(deepLink, messageData)
        })
    }

    private func registerPushOpenedHandler(inAppResponder responder: pushOpenedCompletion? = nil) {
        builder.setPushOpenedHandler(pushOpenedHandlerBlock: { (notification : KSPushNotification) -> Void in
            if let action = notification.actionIdentifier {
                responder?(action, notification.data)
            } else {
                responder?(nil, nil)
            }
        })
    }
}
