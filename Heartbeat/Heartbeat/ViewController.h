//
//  ViewController.h
//  Heartbeat
//
//  Created by pwnlc on 2016/11/24.
//  Copyright © 2016年 xyz.pwnlc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentValueLabel;
@property (weak, nonatomic) IBOutlet UIButton *watchValueButton;
@property (weak, nonatomic) IBOutlet UIScrollView *heartRateScrollView;
@property (weak, nonatomic) IBOutlet UILabel *highestRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentOverLine;

- (IBAction)watchValue:(id)sender;
- (IBAction)resetLineView:(id)sender;
- (IBAction)getLineImage:(id)sender;

@end

