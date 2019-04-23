

import UIKit
import UserNotifications
import OptimoveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        

        let info = OptimoveTenantInfo(tenantToken: "<MY_TENANT_TOKEN>",configName:"<MY_CONFIG_NAME>")
        
        Optimove.configure(for: info)
        
       UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (grant, error) in
            
        }
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if !Optimove.shared.didReceiveRemoteNotification(userInfo: userInfo,
                                                                 didComplete: completionHandler) {
            completionHandler(.newData)
        }
        
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Optimove.shared.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    
    
}

