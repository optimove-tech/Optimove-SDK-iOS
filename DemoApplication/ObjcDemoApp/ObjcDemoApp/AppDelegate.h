//
//  AppDelegate.h
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
@import OptimoveSDK;

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate, OptimoveSuccessStateDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

