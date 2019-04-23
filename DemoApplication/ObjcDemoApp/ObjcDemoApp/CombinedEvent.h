//
//  CombinedEvent.h
//  ObjcDemoApp
//
//  Created by Elkana Orbach on 21/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import <Foundation/Foundation.h>
@import OptimoveSDK;

@interface CombinedEvent : NSObject <OptimoveEvent>

@property (strong, nonatomic) NSString *stringInput;
@property (strong, nonatomic) NSNumber *numberInput;

- (instancetype) initWithStringInput:(NSString*) stringInput andNumberInput:(NSNumber*) numberInput;

@end
