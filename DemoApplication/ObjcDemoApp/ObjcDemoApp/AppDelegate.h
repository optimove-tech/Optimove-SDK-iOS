

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
@import OptimoveSDK;


@interface AppDelegate : UIResponder <UIApplicationDelegate,OptimoveSuccessStateDelegate,UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

