#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    OptimoveTenantInfo *info = [[OptimoveTenantInfo alloc] initWithTenantToken: @"<YOUR_SDK_TENANT_TOKEN>" configName: @"<YOUR_MOBILE_CONFIG_NAME>"];
    [Optimove configureFor: info];
    [Optimove.shared registerSuccessStateDelegate:self];
    [UIApplication.sharedApplication registerForRemoteNotifications];
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
    }];
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    
    return YES;
}



- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![Optimove.shared didReceiveRemoteNotificationWithUserInfo:userInfo didComplete:completionHandler]) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.shared applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)optimove:(Optimove * _Nonnull)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> * _Nonnull)missingPermissions {
   
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (![Optimove.shared willPresentWithNotification:notification withCompletionHandler:completionHandler]) {
        completionHandler(UNAuthorizationOptionAlert | UNAuthorizationOptionSound);
    }
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if(![Optimove.shared didReceiveWithResponse:response withCompletionHandler:completionHandler]) {
        completionHandler();
    }
}

@end
