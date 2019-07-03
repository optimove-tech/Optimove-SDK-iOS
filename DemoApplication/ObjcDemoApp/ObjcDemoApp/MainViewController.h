//
//  ViewController.h
//  HelloWorld
//
//  Created by Elkana Orbach on 14/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import <UIKit/UIKit.h>
@import OptimoveSDK;

@interface MainViewController : UIViewController <OptimoveDeepLinkCallback, OptimoveSuccessStateDelegate>
@property (weak, nonatomic) IBOutlet UILabel *output;


@end

