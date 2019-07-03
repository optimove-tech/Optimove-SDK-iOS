#import "MainViewController.h"

@import OptimoveSDK;

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.shared registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents *) deepLink {
    if (deepLink != nil) {
        // Retrieve the targetted screen name
        NSString* screenName = deepLink.screenName;
        // Retrieve the deep link Key-Value parameters
        NSDictionary* deepLinkParams = deepLink.parameters;
    }
}

- (IBAction)subscribeTotestMode:(UIButton *)sender {
     [Optimove.shared startTestMode];
}

- (IBAction)unsubscribeToTestMode:(UIButton *)sender {
    [Optimove.shared stopTestMode];
}

- (void)optimove:(Optimove *)optimove didBecomeActiveWithMissingPermissions:(NSArray<NSNumber *> *)missingPermissions {
    // Report screen visit like this
    [Optimove.shared setScreenVisitWithScreenPath: @"Home/Store/Footware/Boots" screenTitle: @"<YOUR_TITLE>" screenCategory: @"<OPTIONAL: YOUR_CATEGORY>"];
    // OR like that
    [Optimove.shared setScreenVisitWithScreenPathArray: @[@"Home", @"Store", @"Footware", @"Boots"] screenTitle: @"<YOUR_TITLE>" screenCategory: @"<OPTIONAL: YOUR_CATEGORY>"];
}

@end
