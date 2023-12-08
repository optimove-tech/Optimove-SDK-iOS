//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import ObjectiveC.runtime
import OptimoveCore
import UIKit
import UserNotifications

@available(iOS 10.0, *)
public typealias OptimoveUNAuthorizationCheckedHandler = (UNAuthorizationStatus, Error?) -> Void

let KS_MESSAGE_TYPE_PUSH = 1

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
    fileprivate static func requestToken(_ onAuthorizationStatus: OptimoveUNAuthorizationCheckedHandler? = nil) {
        let center = UNUserNotificationCenter.current()

        let requestToken: () -> Void = {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        let askPermission: () -> Void = {
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .background {
                    onAuthorizationStatus?(.notDetermined,
                                           NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Application not active, aborting push permission request"]) as Swift.Error)
                    return
                }

                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let err = error {
                        onAuthorizationStatus?(.notDetermined, err)
                        return
                    }

                    if !granted {
                        onAuthorizationStatus?(.denied, nil)
                        return
                    }

                    onAuthorizationStatus?(.authorized, nil)
                    requestToken()
                }
            }
        }

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                onAuthorizationStatus?(settings.authorizationStatus, nil)
                return
            case .authorized:
                onAuthorizationStatus?(settings.authorizationStatus, nil)
                requestToken()
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
    static func pushRegister(_ deviceToken: Data) {
        let token = serializeDeviceToken(deviceToken)
        let iosTokenType = getTokenType()

        let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as Any
        let parameters = ["token": token,
                          "type": sharedInstance.pushNotificationDeviceType,
                          "iosTokenType": iosTokenType,
                          "bundleId": bundleId] as [String: Any]

        Optimobile.trackEvent(eventType: OptimobileEvent.PUSH_DEVICE_REGISTER, properties: parameters as [String: AnyObject], immediateFlush: true)
    }

    /**
         Unsubscribe your device from the Optimobile Push service
     */
    static func pushUnregister() {
        Optimobile.trackEvent(eventType: OptimobileEvent.DEVICE_UNSUBSCRIBED, properties: [:], immediateFlush: true)
    }

    // MARK: Open handling

    /**
          Track a user action triggered by a push notification

         Parameters:
             - notification: The notification which triggered the action
     */
    static func pushTrackOpen(notification: PushNotification) {
        let params = ["type": KS_MESSAGE_TYPE_PUSH, "id": notification.message.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_OPENED, properties: params)
    }

    static func pushTrackOpen(userInfo: [AnyHashable: Any]) {
        do {
            let notification = try PushNotification(userInfo: userInfo)
            Optimobile.pushTrackOpen(notification: notification)
        } catch {
            Logger.error(
                """
                Ignoring push notification open.
                Reason: Invalid notification payload.
                Payload: \(userInfo).
                Error: \(error.localizedDescription).
                """
            )
        }
    }

    @available(iOS 10.0, *)
    func pushHandleOpen(withUserInfo userInfo: [AnyHashable: Any]) -> Bool {
        do {
            let notification = try PushNotification(userInfo: userInfo)
            pushHandleOpen(notification: notification)
            pendingNoticationHelper.remove(id: notification.message.id)
            return true
        } catch {
            Logger.error(
                """
                Ignoring push notification open.
                Reason: Invalid notification payload.
                Payload: \(userInfo).
                Error: \(error.localizedDescription).
                """
            )
            return false
        }
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
    func pushHandleDismissed(withUserInfo userInfo: [AnyHashable: Any]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: userInfo)
            let notification = try JSONDecoder().decode(PushNotification.self, from: data)
            pushHandleDismissed(notificationId: notification.message.id)
            pendingNoticationHelper.remove(id: notification.message.id)
            return true
        } catch {
            Logger.error(
                """
                Ignoring push notification dismissed.
                Reason: Invalid notification payload.
                Payload: \(userInfo).
                Error: \(error.localizedDescription).
                """
            )
            return false
        }
    }

    @available(iOS 10.0, *)
    private func pushHandleDismissed(notificationId: Int, dismissedAt: Date? = nil) {
        pendingNoticationHelper.remove(id: notificationId)
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
        if !AppGroupsHelper.isAppGroupDefined() {
            return
        }
        Task {
            do {
                let notifications = await UNUserNotificationCenter.current().deliveredNotifications()
                var actualPendingNotificationIds: [Int] = []
                for notification in notifications {
                    let notification = try PushNotification(userInfo: notification.request.content.userInfo)

                    actualPendingNotificationIds.append(notification.message.id)
                }

                let recordedPendingNotifications = pendingNoticationHelper.readAll()

                let deletions = recordedPendingNotifications.filter { !actualPendingNotificationIds.contains($0.id) }
                for deletion in deletions {
                    pushHandleDismissed(notificationId: deletion.id, dismissedAt: deletion.deliveredAt)
                }
            } catch {
                Logger.error("Failed to track push dismissed events: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Token handling

    fileprivate static func serializeDeviceToken(_ deviceToken: Data) -> String {
        var token = ""
        for i in 0 ..< deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }

        return token
    }

    fileprivate static func getTokenType() -> Int {
        let releaseMode = MobileProvision.releaseMode()

        if let index = [
            .releaseAdHoc,
            .releaseDev,
            .releaseWildcard,
        ].firstIndex(of: releaseMode), index > -1 {
            return releaseMode.rawValue + 1
        }

        return Optimobile.sharedInstance.pushNotificationProductionTokenType
    }
}

// MARK: Swizzling

private var existingDidReg: IMP?
private var existingDidFailToReg: IMP?
private var existingDidReceive: IMP?

class PushHelper {
    typealias kumulos_applicationDidRegisterForRemoteNotifications = @convention(c) (_ obj: UIApplicationDelegate, _ _cmd: Selector, _ application: UIApplication, _ deviceToken: Data) -> Void
    typealias didRegBlock = @convention(block) (_ obj: UIApplicationDelegate, _ application: UIApplication, _ deviceToken: Data) -> Void

    typealias kumulos_applicationDidFailToRegisterForRemoteNotificaitons = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ error: Error) -> Void
    typealias didFailToRegBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ error: Error) -> Void

    typealias kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ userInfo: [AnyHashable: Any], _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
    typealias didReceiveBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ userInfo: [AnyHashable: Any], _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void

    lazy var pushInit: Void = {
        let klass: AnyClass = type(of: UIApplication.shared.delegate!)

        // Did register push delegate
        let didRegisterSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let meth = class_getInstanceMethod(klass, didRegisterSelector)
        let regType = NSString(string: "v@:@@").utf8String
        let regBlock: didRegBlock = { (obj: UIApplicationDelegate, application: UIApplication, deviceToken: Data) in
            if let _ = existingDidReg {
                unsafeBitCast(existingDidReg, to: kumulos_applicationDidRegisterForRemoteNotifications.self)(obj, didRegisterSelector, application, deviceToken)
            }

            Optimobile.pushRegister(deviceToken)
        }
        let kumulosDidRegister = imp_implementationWithBlock(regBlock as Any)
        existingDidReg = class_replaceMethod(klass, didRegisterSelector, kumulosDidRegister, regType)

        // Failed to register handler
        let didFailToRegisterSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        let didFailToRegType = NSString(string: "v@:@@").utf8String
        let didFailToRegBlock: didFailToRegBlock = { (obj: Any, application: UIApplication, error: Error) in
            if let _ = existingDidFailToReg {
                unsafeBitCast(existingDidFailToReg, to: kumulos_applicationDidFailToRegisterForRemoteNotificaitons.self)(obj, didFailToRegisterSelector, application, error)
            }

            print("Failed to register for remote notifications: \(error)")
        }
        let kumulosDidFailToRegister = imp_implementationWithBlock(didFailToRegBlock as Any)
        existingDidFailToReg = class_replaceMethod(klass, didFailToRegisterSelector, kumulosDidFailToRegister, didFailToRegType)

        // iOS9+ content-available handler
        let didReceiveSelector = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let receiveType = NSString(string: "v@:@@@?").utf8String
        let didReceive: didReceiveBlock = { (obj: Any, _ application: UIApplication, userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) in
            do {
                let notification = try PushNotification(userInfo: userInfo)
                let hasInApp = notification.deeplink != nil

                self.setBadge(userInfo: userInfo)
                self.trackPushDelivery(notification: notification)

                if existingDidReceive == nil, !hasInApp {
                    // Nothing to do
                    completionHandler(.noData)
                    return
                } else if existingDidReceive != nil, !hasInApp {
                    // Only existing delegate work to do
                    unsafeBitCast(existingDidReceive, to: kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler.self)(obj, didReceiveSelector, application, userInfo, completionHandler)
                    return
                }

                var fetchResult: UIBackgroundFetchResult = .noData
                let group = DispatchGroup()

                if existingDidReceive != nil {
                    group.enter()
                    DispatchQueue.main.async {
                        unsafeBitCast(existingDidReceive, to: kumulos_applicationDidReceiveRemoteNotificationFetchCompletionHandler.self)(obj, didReceiveSelector, application, userInfo, { (result: UIBackgroundFetchResult) in
                            DispatchQueue.main.async {
                                if fetchResult == .noData {
                                    fetchResult = result
                                }

                                group.leave()
                            }
                        })
                    }
                }

                if hasInApp {
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
                }

                group.notify(queue: .main) {
                    completionHandler(fetchResult)
                }
            } catch {
                Logger.error("Failed to parse push notification: \(error.localizedDescription)")
                completionHandler(.failed)
            }
        }
        let kumulosDidReceive = imp_implementationWithBlock(unsafeBitCast(didReceive, to: AnyObject.self))
        existingDidReceive = class_replaceMethod(klass, didReceiveSelector, kumulosDidReceive, receiveType)
        if #available(iOS 10, *) {
            let delegate = OptimoveUserNotificationCenterDelegate()

            Optimobile.sharedInstance.notificationCenter = delegate
            UNUserNotificationCenter.current().delegate = delegate
        }
    }()

    let optimobileHelper: OptimobileHelper

    init(optimobileHelper: OptimobileHelper) {
        self.optimobileHelper = optimobileHelper
    }

    private func setBadge(userInfo: [AnyHashable: Any]) {
        let badge: NSNumber? = optimobileHelper.getBadgeFromUserInfo(userInfo: userInfo)
        if let newBadge = badge {
            UIApplication.shared.applicationIconBadgeNumber = newBadge.intValue
        }
    }

    private func trackPushDelivery(notification: PushNotification) {
        let props: [String: Any] = ["type": KS_MESSAGE_TYPE_PUSH, "id": notification.message.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DELIVERED, properties: props, immediateFlush: true)
    }
}
