

#import <Foundation/Foundation.h>
@import OptimoveSDK;

@interface CombinedEvent : NSObject <OptimoveEvent>

@property (strong, nonatomic) NSString *stringInput;
@property (strong, nonatomic) NSNumber *numberInput;

- (instancetype) initWithStringInput:(NSString*) stringInput andNumberInput:(NSNumber*) numberInput;

@end
