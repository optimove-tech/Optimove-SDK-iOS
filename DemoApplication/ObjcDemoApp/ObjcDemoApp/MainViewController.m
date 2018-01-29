//
//  ViewController.m
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.sharedInstance registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
    
    [Optimove.sharedInstance setScreenEventWithViewControllersIdetifiers:@[@"vc1",@"vc2"] url:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents *)deepLink {
    
    if (deepLink != nil) {
        UIViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:deepLink.screenName];
        [[self navigationController] pushViewController:vc animated:true];
    }
}
- (IBAction)subscribeTotestMode:(UIButton *)sender {
     [Optimove.sharedInstance subscribeToTestMode];
}

- (IBAction)unsubscribeToTestMode:(UIButton *)sender {
    [Optimove.sharedInstance unSubscribeFromTestMode];
}


@synthesize optimoveStateDelegateID;

- (void)didBecomeActive {
   
}

- (void)didBecomeInvalidWithErrors:(NSArray<NSNumber *> * _Nonnull)errors {
    
}

- (void)didStartLoading {
    
}


@end
