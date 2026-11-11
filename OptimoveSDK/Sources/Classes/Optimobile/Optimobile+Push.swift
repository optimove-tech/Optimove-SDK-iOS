//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import ObjectiveC.runtime
import UIKit
import UserNotifications

public class PushNotification: NSObject {
    static let DeepLinkTypeInApp: Int = 1
    static let DeepLinkTypeOverlayMessaging: Int = 2
    
    public internal(set) var id: Int
    public internal(set) var aps: [AnyHashable: Any]
    public internal(set) var data: [AnyHashable: Any]
    public internal(set) var url: URL?
    public internal(set) var actionIdentifier: String?
    
    init(userInfo: [AnyHashable: Any]?) {
        id = 0
        self.aps = [:]
        self.data = [:]
        
        guard let userInfo = userInfo else {
            return
        }
        
        guard let aps = userInfo["aps"] as? [AnyHashable: Any] else {
            return
        }
        
        self.aps = aps
        
        guard let custom = userInfo["custom"] as? [AnyHashable: Any] else {
            return
        }
        
        guard let data = custom["a"] as? [AnyHashable: Any] else {
            return
        }
        
        self.data = data
        
        guard let msg = data["k.message"] as? [AnyHashable: Any] else {
            return
        }
        
        let msgData = msg["data"] as! [AnyHashable: Any]
        
        id = msgData["id"] as! Int
        
        if let urlStr = custom["u"] as? String {
            url = URL(string: urlStr)
        } else {
            url = nil
        }
    }
    
    @available(iOS 10.0, *)
    convenience init(userInfo: [AnyHashable: Any]?, response: UNNotificationResponse?) {
        self.init(userInfo: userInfo)
        
        if let notificationResponse = response {
            if notificationResponse.actionIdentifier != UNNotificationDefaultActionIdentifier {
                actionIdentifier = notificationResponse.actionIdentifier
            }
        }
    }
    
    var isOverlayMessagingTrigger: Bool {
        guard let deepLink = data["k.deepLink"] as? [AnyHashable: Any] else { return false }
        return deepLink["type"] as? Int == PushNotification.DeepLinkTypeOverlayMessaging
    }
    
    public func inAppDeepLink() -> [AnyHashable: Any]? {
        guard let deepLink = data["k.deepLink"] as? [AnyHashable: Any] else {
            return nil
        }
        
        if deepLink["type"] as? Int != PushNotification.DeepLinkTypeInApp {
            return nil
        }
        
        return deepLink
    }
}

@available(iOS 10.0, *)
public typealias OptimoveUNAuthorizationCheckedHandler = (UNAuthorizationStatus, Error?) -> Void

typealias PushEventTracker = (OptimobileEvent, [String: Any]) -> Void

/// The notification-permission surface the push registration code needs; a seam so tests can fake the system prompt.
protocol PushPermissionCenter {
    func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void)
    func requestAuthorization(_ completion: @escaping (Bool, Error?) -> Void)
}

extension UNUserNotificationCenter: PushPermissionCenter {
    func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        getNotificationSettings { completion($0.authorizationStatus) }
    }

    func requestAuthorization(_ completion: @escaping (Bool, Error?) -> Void) {
        requestAuthorization(options: [.alert, .badge, .sound], completionHandler: completion)
    }
}

extension Optimobile {
    /**
     Helper method for requesting the device token with alert, badge and sound permissions.
     
     On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
     */
    @available(iOS 10.0, *)
    static func pushRequestDeviceToken(_ onAuthorizationStatus: OptimoveUNAuthorizationCheckedHandler? = nil) {
        requestToken(onAuthorizationStatus)
    }
    
    /**
     Helper method for requesting the device token with alert, badge and sound permissions.
     
     On success will raise the didRegisterForRemoteNotificationsWithDeviceToken UIApplication event
     */
    static func pushRequestDeviceToken() {
        if #available(iOS 10.0, *) {
            requestToken()
        } else {
            DispatchQueue.main.async {
                requestTokenLegacy()
            }
        }
    }
    
    @available(iOS 10.0, *)
    static func requestToken(
        center: PushPermissionCenter = UNUserNotificationCenter.current(),
        isInBackground: @escaping () -> Bool = { UIApplication.shared.applicationState == .background },
        registerForRemoteNotifications: @escaping () -> Void = {
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        },
        _ onAuthorizationStatus: OptimoveUNAuthorizationCheckedHandler? = nil
    ) {
        // A push token is registered whatever the permission outcome: the token is what lets silent pushes through.
        let report: (UNAuthorizationStatus, Swift.Error?) -> Void = { status, error in
            onAuthorizationStatus?(status, error)
            registerForRemoteNotifications()
        }

        let askPermission: () -> Void = {
            DispatchQueue.main.async {
                if isInBackground() {
                    report(.notDetermined,
                           NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Application not active, aborting push permission request"]) as Swift.Error)
                    return
                }

                center.requestAuthorization { granted, error in
                    if let err = error {
                        report(.notDetermined, err)
                        return
                    }

                    report(granted ? .authorized : .denied, nil)
                }
            }
        }

        center.authorizationStatus { status in
            switch status {
            case .denied, .authorized:
                report(status, nil)
            default:
                askPermission()
            }
        }
    }
    
    @available(iOS, deprecated: 10.0)
    fileprivate static func requestTokenLegacy() {
        // Determine the type of notifications we want to ask permission for, for example we may want to alert the user, update the badge number and play a sound
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
        
        // Create settings  based on those notification types we want the user to accept
        let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        
        // Get the main application
        let application = UIApplication.shared
        
        // Register the settings created above - will show alert first if the user hasn't previously done this
        // See delegate methods in AppDelegate - the AppDelegate conforms to the UIApplicationDelegate protocol
        application.registerUserNotificationSettings(pushNotificationSettings)
        application.registerForRemoteNotifications()
    }
    
    /**
     Register a device token with the Optimobile Push service
     
     Parameters:
     - deviceToken: The push token returned by the device
     */
    static func pushRegister(
        _ deviceToken: Data,
        deviceType: Int = sharedInstance.pushNotificationDeviceType,
        iosTokenType: Int = getTokenType(),
        center: PushPermissionCenter = UNUserNotificationCenter.current(),
        track: @escaping PushEventTracker = Optimobile.trackPushEvent
    ) {
        let token = serializeDeviceToken(deviceToken)
        let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as Any

        center.authorizationStatus { status in
            let parameters = ["token": token,
                              "type": deviceType,
                              "iosTokenType": iosTokenType,
                              "bundleId": bundleId,
                              "areNotificationsEnabled": notificationsEnabled(status)] as [String: Any]
            track(.PUSH_DEVICE_REGISTER, parameters)
        }
    }

    static func notificationsEnabled(_ status: UNAuthorizationStatus) -> Bool {
        if status == .authorized || status == .provisional {
            return true
        }
        if #available(iOS 14.0, *) {
            return status == .ephemeral
        }
        return false
    }

    /// Sends `k.push.notificationEnablementChanged` when the permission differs from the last value reported
    /// (initially false), so the backend learns about changes made in system settings.
    static func reportNotificationEnablementIfChanged(
        center: PushPermissionCenter = UNUserNotificationCenter.current(),
        track: @escaping PushEventTracker = Optimobile.trackPushEvent
    ) {
        center.authorizationStatus { status in
            let enabled = notificationsEnabled(status)
            let key = OptimobileUserDefaultsKey.NOTIFICATIONS_ENABLED.rawValue
            let persisted = KeyValPersistenceHelper.object(forKey: key) as? Bool ?? false
            if enabled == persisted {
                return
            }

            track(.PUSH_NOTIFICATION_ENABLEMENT_CHANGED, ["notificationsEnabled": enabled])
            KeyValPersistenceHelper.set(enabled, forKey: key)
        }
    }

    static func trackPushEvent(_ event: OptimobileEvent, _ properties: [String: Any]) {
        Optimobile.trackEvent(eventType: event, properties: properties, immediateFlush: true)
    }
    
    /**
     Unsubscribe your device from the Optimobile Push service
     */
    static func pushUnregister(track: PushEventTracker = Optimobile.trackPushEvent) {
        track(.DEVICE_UNSUBSCRIBED, [:])
    }
    
    // MARK: Open handling
    
    /**
     Track a user action triggered by a push notification
     
     Parameters:
     - notification: The notification which triggered the action
     */
    static func pushTrackOpen(notification: PushNotification) {
        if notification.id == 0 {
            Logger.warn("""
            Ignoring push notification open.
            Reason: Invalid notification id (== 0).
            Payload: \(notification).
            """)
        }
        let params = ["type": KS_MESSAGE_TYPE_PUSH, "id": notification.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_OPENED, properties: params)
    }
    
    static func pushTrackOpen(userInfo: [AnyHashable: Any]) {
        let notification = PushNotification(userInfo: userInfo)
        Optimobile.pushTrackOpen(notification: notification)
    }
    
    @available(iOS 10.0, *)
    func pushHandleOpen(withUserInfo: [AnyHashable: Any]?, response: UNNotificationResponse?) -> Bool {
        let notification = PushNotification(userInfo: withUserInfo, response: response)
        
        if notification.id == 0 {
            return false
        }
        
        pushHandleOpen(notification: notification)
        
        PendingNotificationHelper.remove(id: notification.id)
        
        return true
    }
    
    private func pushHandleOpen(notification: PushNotification) {
        Optimobile.pushTrackOpen(notification: notification)
        
        // Handle URL pushes
        
        if let url = notification.url {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:]) { _ in
                    // noop
                }
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        
        inAppManager.handlePushOpen(notification: notification)
        
        if let userOpenedHandler = config.pushOpenedHandlerBlock {
            DispatchQueue.main.async {
                userOpenedHandler(notification)
            }
        }
    }
    
    // MARK: Dismissed handling
    
    @available(iOS 10.0, *)
    func pushHandleDismissed(withUserInfo: [AnyHashable: Any]?, response: UNNotificationResponse?) -> Bool {
        let notification = PushNotification(userInfo: withUserInfo, response: response)
        
        if notification.id == 0 {
            return false
        }
        
        pushHandleDismissed(notificationId: notification.id)
        
        return true
    }
    
    @available(iOS 10.0, *)
    private func pushHandleDismissed(notificationId: Int, dismissedAt: Date? = nil) {
        PendingNotificationHelper.remove(id: notificationId)
        pushTrackDismissed(notificationId: notificationId, dismissedAt: dismissedAt)
    }
    
    @available(iOS 10.0, *)
    private func pushTrackDismissed(notificationId: Int, dismissedAt: Date? = nil) {
        let params = ["type": KS_MESSAGE_TYPE_PUSH, "id": notificationId]
        
        if let unwrappedDismissedAt = dismissedAt {
            Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DISMISSED.rawValue, atTime: unwrappedDismissedAt, properties: params)
        } else {
            Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DISMISSED, properties: params)
        }
    }
    
    @available(iOS 10.0, *)
    func maybeTrackPushDismissedEvents() {
        if !AppGroupsHelper.isKumulosAppGroupDefined() {
            return
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications: [UNNotification]) in
            var actualPendingNotificationIds: [Int] = []
            for notification in notifications {
                let notification = PushNotification(userInfo: notification.request.content.userInfo)
                if notification.id == 0 {
                    continue
                }
                
                actualPendingNotificationIds.append(notification.id)
            }
            
            let recordedPendingNotifications = PendingNotificationHelper.readAll()
            
            let deletions = recordedPendingNotifications.filter { !actualPendingNotificationIds.contains($0.id) }
            for deletion in deletions {
                self.pushHandleDismissed(notificationId: deletion.id, dismissedAt: deletion.deliveredAt)
            }
        }
    }
    
    // MARK: Token handling
    
    static func serializeDeviceToken(_ deviceToken: Data) -> String {
        var token = ""
        for i in 0 ..< deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        
        return token
    }
    
    static func getTokenType() -> Int {
#if targetEnvironment(simulator)
        return 2 // sandbox APNs: simulator tokens are always sandbox
#else
        let releaseMode = MobileProvision.releaseMode()
        
        if let index = [
            .releaseAdHoc,
            .releaseDev,
            .releaseWildcard,
        ].firstIndex(of: releaseMode), index > -1 {
            return releaseMode.rawValue + 1
        }
        
        return Optimobile.sharedInstance.pushNotificationProductionTokenType
#endif
    }
}

// MARK: Swizzling

private var existingDidReg: IMP?
private var existingDidRegTarget: AnyObject?

private var existingDidFailToReg: IMP?
private var existingDidFailTarget: AnyObject?

private var existingDidReceive: IMP?
private var existingDidReceiveTarget: AnyObject?

class PushHelper {
    typealias kumulos_applicationDidRegisterForRemoteNotifications = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ deviceToken: Data) -> Void
    typealias didRegBlock = @convention(block) (_ obj: UIApplicationDelegate, _ application: UIApplication, _ deviceToken: Data) -> Void
    
    typealias kumulos_applicationDidFailToRegisterForRemoteNotificaitons = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ error: Error) -> Void
    typealias didFailToRegBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ error: Error) -> Void
    
    typealias kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ userInfo: [AnyHashable: Any], _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
    typealias didReceiveBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ userInfo: [AnyHashable: Any], _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
    
    lazy var pushInit: Void = {
        let delegate = UIApplication.shared.delegate!
        
        // Get the actual runtime class of the delegate instance to co-exist with other swizzling flows
        let klass: AnyClass = object_getClass(delegate)!
        
        self.swizzleDidRegister(delegate: delegate, klass: klass)
        self.swizzleDidFailRegister(delegate: delegate, klass: klass)
        self.swizzleDidReceive(delegate: delegate, klass: klass)
        self.setUserNotificationCenterDelegates()
    }()
    
    private func swizzleDidRegister(delegate: UIApplicationDelegate, klass: AnyClass) {
        let didRegisterSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let regType = NSString(string: "v@:@@").utf8String
        let regBlock: didRegBlock = { (obj: Any, application: UIApplication, deviceToken: Data) in
            if let _ = existingDidReg {
                let targetObj = existingDidRegTarget ?? obj
                if (targetObj as AnyObject).responds(to: didRegisterSelector) {
                    unsafeBitCast(existingDidReg, to: kumulos_applicationDidRegisterForRemoteNotifications.self)(targetObj, didRegisterSelector, application, deviceToken)
                }
            }
            
            Optimobile.pushRegister(deviceToken)
        }
        let kumulosDidRegister = imp_implementationWithBlock(regBlock as Any)
        existingDidReg = class_replaceMethod(klass, didRegisterSelector, kumulosDidRegister, regType)
        
        if existingDidReg != nil {
            return
        }
        
        existingDidReg = self.getForwardingImpl(target: delegate, originalSelector: didRegisterSelector)
        
        if existingDidReg == nil {
            return
        }
        
        if let obj = delegate as? NSObject, let ft = obj.forwardingTarget(for: didRegisterSelector) {
            existingDidRegTarget = ft as AnyObject
        }
        
    }
    
    private func swizzleDidFailRegister(delegate: UIApplicationDelegate, klass: AnyClass) {
        let klass: AnyClass = object_getClass(delegate)!
        
        let didFailToRegisterSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        let didFailToRegType = NSString(string: "v@:@@").utf8String
        let didFailToRegBlock: didFailToRegBlock = { (obj: Any, application: UIApplication, error: Error) in
            if let _ = existingDidFailToReg {
                let targetObj = existingDidFailTarget ?? obj
                if (targetObj as AnyObject).responds(to: didFailToRegisterSelector) {
                    unsafeBitCast(existingDidFailToReg, to: kumulos_applicationDidFailToRegisterForRemoteNotificaitons.self)(targetObj, didFailToRegisterSelector, application, error)
                }
            }
            
            print("Failed to register for remote notifications: \(error)")
        }
        
        let kumulosDidFailToRegister = imp_implementationWithBlock(didFailToRegBlock as Any)
        existingDidFailToReg = class_replaceMethod(klass, didFailToRegisterSelector, kumulosDidFailToRegister, didFailToRegType)
        
        if existingDidFailToReg != nil {
            return
        }
        
        existingDidFailToReg = self.getForwardingImpl(target: delegate, originalSelector: didFailToRegisterSelector)
        
        if existingDidFailToReg == nil {
            return
        }
        
        if let obj = delegate as? NSObject, let ft = obj.forwardingTarget(for: didFailToRegisterSelector) {
            existingDidFailTarget = ft as AnyObject
        }
    }
    
    private func swizzleDidReceive(delegate: UIApplicationDelegate, klass: AnyClass) {
        // iOS9+ content-available handler
        let didReceiveSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let receiveType = NSString(string: "v@:@@@?").utf8String
        let didReceive = createDidReceiveBlock(didReceiveSelector: didReceiveSelector)
        
        let kumulosDidReceive = imp_implementationWithBlock(unsafeBitCast(didReceive, to: AnyObject.self))
        existingDidReceive = class_replaceMethod(klass, didReceiveSelector, kumulosDidReceive, receiveType)
        
        if existingDidReceive != nil {
            return
        }
        
        existingDidReceive = self.getForwardingImpl(target: delegate, originalSelector: didReceiveSelector)
        
        
        if existingDidReceive == nil {
            return
        }
        
        if let obj = delegate as? NSObject, let ft = obj.forwardingTarget(for: didReceiveSelector) {
            existingDidReceiveTarget = ft as AnyObject
        }
    }
    
    private func setUserNotificationCenterDelegates(){
        if #available(iOS 10, *) {
            let delegate = OptimoveUserNotificationCenterDelegate()
            
            Optimobile.sharedInstance.notificationCenter = delegate
            UNUserNotificationCenter.current().delegate = delegate
        }
    }
    
    private func getForwardingImpl(target: AnyObject, originalSelector: Selector) -> IMP?{
        let selector = NSSelectorFromString("forwardingTargetForSelector:")
        if target.responds(to: selector),
           let forwardingTargetMethod = class_getInstanceMethod(type(of: target), selector) {
            
            typealias ForwardingTargetFunction = @convention(c) (AnyObject, Selector, Selector) -> AnyObject?
            let implementation = method_getImplementation(forwardingTargetMethod)
            let function = unsafeBitCast(implementation, to: ForwardingTargetFunction.self)
            
            if let forwardingTarget = function(target, selector, originalSelector),
               forwardingTarget.responds(to: originalSelector) {
                guard let method = class_getInstanceMethod(type(of: forwardingTarget), originalSelector) else { return nil }
                
                let implementation = method_getImplementation(method)
                
                return implementation
            }
            
            
        }
        
        return nil
    }
    
    
    private func setBadge(userInfo: [AnyHashable: Any]) {
        let badge: NSNumber? = OptimobileHelper.getBadgeFromUserInfo(userInfo: userInfo)
        if let newBadge = badge {
            UIApplication.shared.applicationIconBadgeNumber = newBadge.intValue
        }
    }
    
    private func trackPushDelivery(notification: PushNotification) {
        if notification.id == 0 {
            return
        }
        
        let props: [String: Any] = ["type": KS_MESSAGE_TYPE_PUSH, "id": notification.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DELIVERED, properties: props, immediateFlush: true)
    }
    
    private func createDidReceiveBlock(didReceiveSelector: Selector) -> didReceiveBlock {
        return { (obj: Any, application: UIApplication, userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) in
            let notification = PushNotification(userInfo: userInfo)
            let hasInApp = notification.inAppDeepLink() != nil
            
            self.setBadge(userInfo: userInfo)
            self.trackPushDelivery(notification: notification)
            
            if notification.isOverlayMessagingTrigger,
               Optimobile.sharedInstance.config.isOverlayMessagingEnabled {
                DispatchQueue.main.async {
                    OptimoveOverlayMessaging.onPushTriggerReceived()
                }
            }
            
            if existingDidReceive == nil, !hasInApp {
                // Nothing to do
                completionHandler(.noData)
                return
            }
            
            if existingDidReceive != nil, !hasInApp {
                // Only existing delegate work to do
                let targetObj = existingDidReceiveTarget ?? obj
                if (targetObj as AnyObject).responds(to: didReceiveSelector) {
                    unsafeBitCast(existingDidReceive, to: kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler.self)(targetObj, didReceiveSelector, application, userInfo, completionHandler)
                }
                
                return
            }
            
            var fetchResult: UIBackgroundFetchResult = .noData
            let group = DispatchGroup()
            
            if existingDidReceive != nil {
                group.enter()
                DispatchQueue.main.async {
                    let targetObj = existingDidReceiveTarget ?? obj
                    if (targetObj as AnyObject).responds(to: didReceiveSelector) {
                        
                        unsafeBitCast(existingDidReceive, to: kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler.self)(targetObj, didReceiveSelector, application, userInfo, { (result: UIBackgroundFetchResult) in
                            DispatchQueue.main.async {
                                if fetchResult == .noData {
                                    fetchResult = result
                                }
                                
                                group.leave()
                            }
                        })
                    } else {
                        group.leave()
                    }
                }
            }
            
            // hasInApp true
            group.enter()
            Optimobile.sharedInstance.inAppManager.sync { (result: Int) in
                DispatchQueue.main.async {
                    if result < 0 {
                        fetchResult = .failed
                    } else if result > 0 {
                        fetchResult = .newData
                    }
                    // No data case is default, allow override from other handler
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completionHandler(fetchResult)
            }
        }
    }
}
