#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.shared registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
    [Optimove.shared setScreenVisitWithScreenPathArray:@[@"vc1",@"vc2"] screenTitle:@"vc2" screenCategory:nil];
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
     [Optimove.shared startTestMode];
}

- (IBAction)unsubscribeToTestMode:(UIButton *)sender {
    [Optimove.shared stopTestMode];
}

- (void)optimove:(Optimove *)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> *)missingPermissions
{}

@end
