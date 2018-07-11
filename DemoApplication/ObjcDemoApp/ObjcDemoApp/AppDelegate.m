
#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
@import OptimoveSDK;


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    OptimoveTenantInfo* info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com" token:@"demo_apps" version:@"1.0.0" hasFirebase:NO useFirebaseMessaging:NO];
    
    [Optimove.sharedInstance configureFor:info];
    
    [Optimove.sharedInstance registerSuccessStateDelegate:self ];
    [UIApplication.sharedApplication registerForRemoteNotifications];
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    
    [[UNUserNotificationCenter currentNotificationCenter]requestAuthorizationWithOptions:UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Your app specific logic goes here
    }];
    
    return YES;
}

- (void)optimove:(Optimove *)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> *)missingPermissions {
    
}
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // Forward the callback to the Optimove SDK
    if (![Optimove.sharedInstance didReceiveRemoteNotificationWithUserInfo:userInfo didComplete:completionHandler]) {
        // The push message was not targeted for Optimove SDK. Implement your logic here or leave as is.
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.sharedInstance applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // Forward the callback to the SDK first
    if (![Optimove.sharedInstance willPresentWithNotification:notification withCompletionHandler:completionHandler]) {
        // The callback was NOT processed by the SDK, apply your app's logic here
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    // Forward the callback to the SDK first
    if (![Optimove.sharedInstance didReceiveWithResponse:response withCompletionHandler:completionHandler]) {
         // The callback was NOT processed by the SDK, apply your app's logic here
        completionHandler();
    }
}


@end
