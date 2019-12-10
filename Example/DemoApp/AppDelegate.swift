import UIKit
import UserNotifications
import OptimoveSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Initialize the Optimove SDK
        let info = OptimoveTenantInfo(tenantToken: "<YOUR_TENANT_TOKEN>",configName:"<YOUR_CONFIG_NAME>")
        Optimove.configure(for: info)
        
        // Mandatory Remote Notification Registration
        UIApplication.shared.registerForRemoteNotifications()
        
        // Optipush Notification Registration
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (grant, error) in
            // Add your response handling logic here
        }
        
        return true
    }
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        let isHandledByOptimove = Optimove.shared.didReceiveRemoteNotification(userInfo: userInfo, didComplete: completionHandler)
        if isHandledByOptimove { return }
        // The remote notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Optimove.shared.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
 
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let isHandledByOptimove = Optimove.shared.didReceive(response: response, withCompletionHandler: completionHandler)
        if isHandledByOptimove { return }
        // The notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let isHandledByOptimove = Optimove.shared.willPresent(notification: notification, withCompletionHandler: completionHandler)
        if isHandledByOptimove { return }
        // The notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
        completionHandler([.alert, .badge, .sound])
    }
}
