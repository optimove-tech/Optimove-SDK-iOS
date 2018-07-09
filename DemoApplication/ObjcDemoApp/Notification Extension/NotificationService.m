

#import "NotificationService.h"
@import OptimoveNotificationServiceExtension;


@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@property (nonatomic, strong) OptimoveNotificationServiceExtension* optimoveNotificationExtenstion;

@end

@implementation NotificationService
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    NotificationExtensionTenantInfo* info = [[NotificationExtensionTenantInfo alloc] initWithEndpoint:@"https://appcontrollerproject-developer.firebaseapp.com" token:@"demo_apps" version:@"1.0.0" appBundleId:@"com.optimove.sdk.demo.objc"];
    self.optimoveNotificationExtenstion = [[OptimoveNotificationServiceExtension alloc]initWithTenantInfo:info];
    if (![self.optimoveNotificationExtenstion didReceive:request withContentHandler:contentHandler]) {
        
        self.contentHandler = contentHandler;
        self.bestAttemptContent = [request.content mutableCopy];
        
        // Modify the notification content here...
        self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
        
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)serviceExtensionTimeWillExpire {
    if (!self.optimoveNotificationExtenstion.isHandledByOptimove) {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
