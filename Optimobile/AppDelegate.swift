//
//  AppDelegate.swift
//  Optimobile
//
//  Created by Barak Ben Hur on 04/04/2022.
//

import UIKit
import KumulosSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let builder = KSConfigBuilder(apiKey: "2b16f7c7-6f0e-46c1-979f-1c13b5fd8a0f", secretKey: "Xh62vshcS15xJCjSHiQ2dcPvfXHVirKdT+Vg").enableInAppMessaging(inAppConsentStrategy: InAppConsentStrategy.AutoEnroll).setPushOpenedHandler(pushOpenedHandlerBlock: { (notification : KSPushNotification) -> Void in
            //- Inspect notification data and do work.
            if let action = notification.actionIdentifier {
                print("User pressed an action button.")
                print(action)
                print(notification.data)
            } else {
                print("Just an open event.")
            }
        }).setInAppDeepLinkHandler(inAppDeepLinkHandlerBlock: { buttonPress in
            let deepLink = buttonPress.deepLinkData
            let messageData = buttonPress.messageData
            print(deepLink)
            print(messageData ?? "")
            // TODO: Inspect the deep link & message data to perform relevant action
        }).setPushOpenedHandler(pushOpenedHandlerBlock: { (notification : KSPushNotification) -> Void in
            print(notification)
        }).enableDeepLinking({ (resolution) in
            print("Deep link resolution result: \(resolution)")
        }).enableCrash()
        Kumulos.initialize(config: builder.build())
        
        let installId = Kumulos.installId
        
        print(installId)
        
        Kumulos.pushRequestDeviceToken()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

