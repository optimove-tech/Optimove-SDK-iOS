//
//  CombinedEvent.m
//  ObjcDemoApp
//
//  Created by Elkana Orbach on 21/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "CombinedEvent.h"
@import OptimoveSDK;

@implementation CombinedEvent

- (instancetype) initWithStringInput:(NSString*) stringInput andNumberInput:(NSNumber*) numberInput {
    
    if ((self = [super init])) {
        _stringInput = stringInput;
        _numberInput = numberInput;
    }
    return self;
}

- (NSString*) name {
    return @"simple_custom_event";
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
