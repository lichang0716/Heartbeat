//
//  SettingViewController.h
//  Heartbeat
//
//  Created by pwnlc on 2016/11/24.
//  Copyright © 2016年 xyz.pwnlc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *defaultTopValueTextField;
- (IBAction)saveValue:(id)sender;
@end
