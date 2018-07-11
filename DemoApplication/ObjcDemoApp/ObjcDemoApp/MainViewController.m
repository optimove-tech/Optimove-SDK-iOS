

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.sharedInstance registerSuccessStateDelegate:self];
    [Optimove.sharedInstance registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL* url = [[NSURL alloc] initWithString:@"http://my.bundle.id/main/cart/pre_checkout"];
    [Optimove.sharedInstance reportScreenVisitWithViewControllersIdentifiers:@[@"main",@"cart"] url:url category:@"Shoes"];
}


- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents *)deepLink {
    if (deepLink != nil) {
        UIViewController* vc = [[self storyboard] instantiateViewControllerWithIdentifier:deepLink.screenName];
        [[self navigationController] pushViewController:vc animated:true];
    }
}
- (IBAction)subscribeTotestMode:(UIButton *)sender {
     [Optimove.sharedInstance startTestMode];
}

- (IBAction)unsubscribeToTestMode:(UIButton *)sender {
    [Optimove.sharedInstance stopTestMode];
}

- (void)optimove:(Optimove *)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> *)missingPermissions {
    [Optimove.sharedInstance reportScreenVisitWithViewControllersIdentifiers:@[@"vc1",@"vc2"] url:nil category:nil];
    [Optimove.sharedInstance unregisterSuccessStateDelegate:self];
}


@end
