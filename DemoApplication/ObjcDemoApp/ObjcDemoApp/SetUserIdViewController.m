//
//  setUserIdViewController.m
//  HelloWorld
//
//  Created by Elkana Orbach on 17/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "SetUserIdViewController.h"

@implementation SetUserIdViewController
- (IBAction)userPressOnSend {
    NSString* name = [self.userIdTextField text];
    [Optimove.shared setUserId:name];
    [Optimove.shared registerUserWithSdkId: @"<SDK_ID>" email: @"<EMAIL>"]
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Optimove.shared setScreenVisitWithScreenPathArray:@[@"main_screen",@"set user id"]  screenTitle:@"set user id" screenCategory:nil];
}
@end
