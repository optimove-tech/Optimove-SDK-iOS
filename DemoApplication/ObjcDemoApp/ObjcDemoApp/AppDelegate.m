//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    OptimoveTenantInfo *info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com"
                                                                 token:@"demo_apps"
                                                               version:@"1.0.0"
                                                           hasFirebase:NO];
    [Optimove.sharedInstance configureWithInfo:info];
    [Optimove.sharedInstance registerWithStateDelegate:self];
    
    return YES;
}


- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [Optimove.sharedInstance handleRemoteNotificationArrivedWithUserInfo:userInfo fetchCompletionHandler:completionHandler];
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.sharedInstance applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

@synthesize optimoveStateDelegateID;

- (void)didBecomeActive {
    NSLog(@"did become active");
}

- (void)didStartLoading {
    NSLog(@"did become loading");
}

- (void)didBecomeInvalidWithErrors:(NSArray<NSNumber *> * _Nonnull)errors {
    NSLog(@"did become invalid");
}

@end
