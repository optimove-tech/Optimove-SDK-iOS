#import "PlacedOrderEvent.h"

@implementation PlacedOrderEvent

- (instancetype) initWithCartItems:(NSArray *)cartItems {
    if ((self = [super init])) {
        self._cartItems = cartItems;
    }
    return self;
}

- (NSString *)name {
    return @"placed_order";
}

- (NSDictionary *)parameters {
    NSDictionary *params = [[NSDictionary alloc] init];
    NSNumber *totalPrice = [NSNumber numberWithInteger:0];
    for (int i = 0; i <= self._cartItems.count; i++) {
        CartItem *item = self._cartItems[i];
        [params setValue:item.name forKey: [NSString stringWithFormat: @"item_name_%d", i]];
        [params setValue:item.price forKey: [NSString stringWithFormat: @"item_price_%d", i]];
        [params setValue:item.image forKey: [NSString stringWithFormat: @"item_image_%d", i]];
        totalPrice = [NSNumber numberWithFloat: [item.price floatValue] + [totalPrice floatValue]];
    }
    [params setValue:totalPrice forKey:@"total_price"];
    return params;
}

@end
