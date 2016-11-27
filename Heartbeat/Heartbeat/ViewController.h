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
@property (weak, nonatomic) IBOutlet UIImageView *heartImageView;
- (IBAction)watchValue:(id)sender;

@end

