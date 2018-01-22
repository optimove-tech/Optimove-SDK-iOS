//
//  AppDelegate.swift
//  swift
//
//  Created by Elkana Orbach on 22/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let url =  "https://appcontrollerproject-developer.firebaseapp.com"
        let token = "demo_apps"
        let version = "1.0.0"
        let info = OptimoveTenantInfo(url: url,
                                      token: token,
                                      version: version,
                                      hasFirebase: false)
        
        Optimove.sharedInstance.configure(info: info)
        
        
        return true
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        Optimove.sharedInstance.handleRemoteNotificationArrived(userInfo: userInfo,
                                                                fetchCompletionHandler: completionHandler)
        
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Optimove.sharedInstance.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

