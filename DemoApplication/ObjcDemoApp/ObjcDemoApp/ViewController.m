//
//  ViewController.m
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.sharedInstance registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
    // Do any additional setup after loading the view, typically from a nib.
//    [Optimove.sharedInstance setScreenEventWithViewControllersIdetifiers:["viewController1","viewcontroller2"] url:nil];
    [Optimove.sharedInstance setScreenEventWithViewControllersIdetifiers:@[@"vc1",@"vc2"] url:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Optimove.sharedInstance subscribeToTestMode];
    [Optimove.sharedInstance registerWithStateDelegate:self];
    
//    [Optimove.sharedInstance [reportEventWithEvent: completionHandler:nil]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents *)deepLink {
    ViewController* vc = [[ViewController alloc] initWithNibName:deepLink.screenName bundle:nil];
    [[self navigationController] pushViewController:vc animated:true];
}


@synthesize optimoveStateDelegateID;

- (void)didBecomeActive {
   
}

- (void)didBecomeInvalidWithErrors:(NSArray<NSNumber *> * _Nonnull)errors {
    
}

- (void)didStartLoading {
    
}


@end
