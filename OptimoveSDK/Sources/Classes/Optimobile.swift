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
    
    private var builder: KSConfigBuilder!
    private var tenantInfo: TenantInfo!
    
    private init() {}
    
    public static func configure(for tenantInfo: TenantInfo) -> Optimobile {
        _sheard.tenantInfo = tenantInfo
        _sheard.builder = KSConfigBuilder(apiKey: tenantInfo.apiKey, secretKey: tenantInfo.secretKey)
        
        return _sheard
    }
    
    public func initilize() {
        let optimoveTenantInfo = OptimoveTenantInfo(tenantToken: tenantInfo.tenantToken, configName: tenantInfo.configName)
        Optimove.configure(for: optimoveTenantInfo)
        Kumulos.initialize(config: builder.build())
    }
    
    public func registerUser(sdkId userID: String, email: String) {
        Optimove.shared.registerUser(sdkId: userID, email: email)
        Kumulos.associateUserWithInstall(userIdentifier: userID, attributes: [
            "email": email as AnyObject
        ])
    }
    
    public func setUserId(_ userID: String) {
        Optimove.shared.setUserId(userID)
        Kumulos.associateUserWithInstall(userIdentifier: userID)
    }
    
    public func setUserEmail(email: String) {
        Optimove.shared.setUserEmail(email: email)
        Kumulos.associateUserWithInstall(userIdentifier: email)
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
        Kumulos.pushUnregister()
    }
    
    public func enablePushCampaigns() {
        Kumulos.pushRequestDeviceToken()
    }
    
    //    public static func sendLocationUpdate(location: CLLocation) {
    //        Kumulos.sendLocationUpdate(location: location)
    //    }
    //
    //    public static func sendiBeaconProximity(beacon: CLBeacon) {
    //        Kumulos.sendiBeaconProximity(beacon: beacon)
    //    }
    
    @discardableResult public func registerInApp(inAppConsentStrategy: InAppConsentStrategy, inAppResponder responder: @escaping InAppDeepLinkHandlerBlock) -> Optimobile {
        builder.enableInAppMessaging(inAppConsentStrategy: inAppConsentStrategy).setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: responder)
        return self
    }
    
    @discardableResult public func registerDeepLink(inAppDeepLinkHandlerBlock: @escaping DeepLinkHandler) -> Optimobile {
        builder.enableDeepLinking(inAppDeepLinkHandlerBlock)
        return self
    }
    
    @discardableResult public func registerPushOpenedHandler(inAppResponder responder: @escaping PushOpenedHandlerBlock) -> Optimobile {
        builder.setPushOpenedHandler(pushOpenedHandlerBlock: responder)
        return self
    }
}
