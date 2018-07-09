import UIKit
import UserNotifications
import OptimoveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let url =  "https://appcontrollerproject-developer.firebaseapp.com"
        let token = "demo_apps"
        let version = "1.0.0"
        let info = OptimoveTenantInfo(url: url, token: token, version: version, hasFirebase: false, useFirebaseMessaging: false)
        Optimove.sharedInstance.configure(for: info)
        
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { (_, _) in
            
        }
        
        
        return true
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if !Optimove.sharedInstance.didReceiveRemoteNotification(userInfo: userInfo, didComplete: completionHandler) {
            completionHandler(.newData)
        }
        
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Optimove.sharedInstance.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if !Optimove.sharedInstance.didReceive(response: response, withCompletionHandler: completionHandler){
            completionHandler()
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if !Optimove.sharedInstance.willPresent(notification: notification, withCompletionHandler: completionHandler) {
            completionHandler([.alert,.badge,.sound])
        }
    }
}

