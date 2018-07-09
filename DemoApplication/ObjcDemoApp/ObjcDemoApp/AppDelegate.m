
#import "AppDelegate.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    OptimoveTenantInfo* info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com" token:@"demo_apps" version:@"1.0.0" hasFirebase:NO useFirebaseMessaging:NO];
    
    [Optimove.sharedInstance configureFor:info];
    
    
    return YES;
}


- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![Optimove.sharedInstance didReceiveRemoteNotificationWithUserInfo:userInfo didComplete:completionHandler]) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.sharedInstance applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


@end
