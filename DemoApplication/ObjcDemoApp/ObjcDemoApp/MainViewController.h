
#import <UIKit/UIKit.h>
@import OptimoveSDK;

@interface MainViewController : UIViewController <OptimoveDeepLinkCallback,OptimoveSuccessStateDelegate>
@property (weak, nonatomic) IBOutlet UILabel *output;


@end

