//
//  MyCustomEvent.m
//  ObjcDemoApp
//
//  Created by Elkana Orbach on 10/07/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

@import OptimoveSDK;

@interface MyCustomEvent : NSObject <OptimoveEvent>

@end
@implementation MyCustomEvent


@synthesize name;

@synthesize parameters;

- (instancetype) initWithName:(NSString*) name andParameters:(NSDictionary*) parameters {
    
    if ((self = [super init])) {
        name = name;
        parameters = parameters;
    }
    return self;
}

@end
