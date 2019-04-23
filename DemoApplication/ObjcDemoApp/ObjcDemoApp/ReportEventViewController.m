//
//  ReportEventViewController.m
//  HelloWorld
//
//  Created by Elkana Orbach on 18/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

#import "ReportEventViewController.h"
@import OptimoveSDK;
#import "CombinedEvent.h"

@interface ReportEventViewController ()

@end

@implementation ReportEventViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)userPressOnSend:(UIButton *)sender {
    NSString* stringInput = _stringTextField.text;
    NSNumber* numberInput = @([_numberTextField.text intValue]);
    CombinedEvent* event = [[CombinedEvent alloc] initWithStringInput:stringInput andNumberInput:numberInput];
    [Optimove.shared reportEvent:event];
}


@end
