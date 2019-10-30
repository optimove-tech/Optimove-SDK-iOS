#import "AppDelegate.h"
@import OptimoveSDK;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize the Optimove SDK
    OptimoveTenantInfo *info = [[OptimoveTenantInfo alloc] initWithTenantToken: @"<YOUR_TENANT_TOKEN>" configName: @"<YOUR_CONFIG_NAME>"];
    [Optimove configureFor: info];
    
    // Mandatory Remote Notification Registration
    [UIApplication.sharedApplication registerForRemoteNotifications];
    
    // Optipush Notification Registration
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Add your response handling logic here
    }];
    
    return YES;
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    BOOL isHandledByOptimove = [Optimove.shared didReceiveRemoteNotificationWithUserInfo:userInfo didComplete:completionHandler];
    if (isHandledByOptimove) { return; }
    // The remote notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.shared applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    BOOL isHandledByOptimove = [Optimove.shared willPresentWithNotification:notification withCompletionHandler:completionHandler];
    if (isHandledByOptimove) { return; }
    // The notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
    completionHandler(UNAuthorizationOptionAlert | UNAuthorizationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    BOOL isHandledByOptimove = [Optimove.shared didReceiveWithResponse:response withCompletionHandler:completionHandler];
    if (isHandledByOptimove) { return; }
    // The notification didn't originate from Optimove's servers, so the app must handle it. Below is the default implementation
    completionHandler();
}

@end
