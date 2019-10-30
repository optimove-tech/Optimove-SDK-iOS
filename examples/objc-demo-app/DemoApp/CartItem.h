//
//  CartItem.h
//  DemoApp
//
//  Created by Noy Grisaru on 22/07/2019.
//  Copyright © 2019 Optimove. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CartItem : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *price;
@property (strong, nonatomic) NSString *image;

@end

NS_ASSUME_NONNULL_END
