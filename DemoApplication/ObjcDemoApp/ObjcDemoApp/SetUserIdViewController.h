

#import <UIKit/UIKit.h>
@import OptimoveSDK;


@interface SetUserIdViewController : UIViewController <OptimoveSuccessStateDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userIdTextField;

@end
