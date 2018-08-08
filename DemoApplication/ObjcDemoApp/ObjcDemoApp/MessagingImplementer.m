//
//  MessagingImplementer.m
//  ObjcDemoApp
//
//  Created by Elkana Orbach on 29/07/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "MessagingImplementer.h"
@import Firebase;
@import OptimoveSDK;

@interface MessagingImplementer : NSObject <OptimoveSuccessStateDelegate,FIRMessagingDelegate>
@property (nonatomic,strong) NSString* fcmToken;
@end

@implementation MessagingImplementer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [FIRMessaging messaging].delegate = self;
    }
    return self;
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    self.fcmToken = fcmToken;
    // Only when Firebase has successfully generated a token, register as an Optimove State Listener, thus solving the race condition issue
    [[Optimove sharedInstance] registerSuccessStateDelegate:self];
    // Continue with app logic here
}

- (void)optimove:(Optimove * _Nonnull)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> * _Nonnull)missingPermissions {
    // Optimove AND Firebase have both initialized successfully, forward the call safely to Optimove
    [[Optimove sharedInstance]optimoveWithDidReceiveFirebaseRegistrationToken:_fcmToken];
    // Unregister the listener to release the reference that the SDK holds and prevent a memory leak
    [[Optimove sharedInstance] unregisterSuccessStateDelegate:self];
    
}

@end
