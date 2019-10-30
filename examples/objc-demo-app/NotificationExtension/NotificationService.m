#import "NotificationService.h"
@import OptimoveNotificationServiceExtension;

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@property (nonatomic, strong) OptimoveNotificationServiceExtension* optimoveNotificationExtenstion;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    self.optimoveNotificationExtenstion = [[OptimoveNotificationServiceExtension alloc] init];
    if ([self.optimoveNotificationExtenstion didReceive:request withContentHandler:contentHandler]) {
        // Notification was sent by Optimove servers, the app can ignore it
        return;
    }
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    
    self.contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    if (self.optimoveNotificationExtenstion.isHandledByOptimove) {
        // Notification was sent by Optimove servers, the app can ignore it
        [self.optimoveNotificationExtenstion serviceExtensionTimeWillExpire];
    } else {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
