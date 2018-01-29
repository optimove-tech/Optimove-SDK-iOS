//
//  ViewController.h
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjcDemoApp-Swift.h"

@interface MainViewController : UIViewController <OptimoveDeepLinkCallback,OptimoveStateDelegate>
@property (weak, nonatomic) IBOutlet UILabel *output;


@end

