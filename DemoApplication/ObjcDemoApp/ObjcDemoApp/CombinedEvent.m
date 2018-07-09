
#import "CombinedEvent.h"

@implementation CombinedEvent

- (instancetype) initWithStringInput:(NSString*) stringInput andNumberInput:(NSNumber*) numberInput {
    
    if ((self = [super init])) {
        _stringInput = stringInput;
        _numberInput = numberInput;
    }
    return self;
}

- (NSString*) name {
    return @"custom_combined_event";
}



- (NSDictionary*) parameters {
    
    NSMutableDictionary* res = [NSMutableDictionary dictionary];
    
    if (_stringInput) {

        res[@"string_param"] = _stringInput;

    }
    if (_numberInput) {

        res[@"number_param"] = _numberInput;

    }
    return res;
}



@end
