//
//  SettingViewController.m
//  Heartbeat
//
//  Created by pwnlc on 2016/11/24.
//  Copyright © 2016年 xyz.pwnlc. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController
@synthesize defaultTopValueTextField = _defaultTopValueTextField;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _defaultTopValueTextField.text = @"160";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)saveValue:(id)sender {
    NSLog(@"点击保存数值");
}
@end
