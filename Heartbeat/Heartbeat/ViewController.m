//
//  ViewController.m
//  Heartbeat
//
//  Created by pwnlc on 2016/11/24.
//  Copyright © 2016年 xyz.pwnlc. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Defines.h"
#import "PNChart.h"


@interface ViewController () {
    BOOL shakePhone;
    NSInteger settedValue;
    NSMutableArray *heartRateArr;
    NSMutableArray *settedRateArr;
    NSMutableArray *timeArr;
    PNLineChart *lineChart;
    
}
@property (nonatomic, strong) HKHealthStore *healthStore;

@end

@implementation ViewController
@synthesize currentValueLabel = _currentValueLabel;
@synthesize watchValueButton = _watchValueButton;
@synthesize heartRateScrollView = _heartRateScrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (![HKHealthStore isHealthDataAvailable]) {
        NSLog(@"设备不支持 HealthKit");
    }
    self.healthStore = [[HKHealthStore alloc] init];
    
    HKObjectType *heartBeatValue = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    NSSet *healthSet = [NSSet setWithObjects:heartBeatValue, nil];
    
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"获取心率权限");
            [self readHeartbeatValue];
            
            NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(readHeartbeatValue) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        } else {
            NSLog(@"获取权限失败");
        }
    }];
    
    shakePhone = NO;
    
    heartRateArr = [[NSMutableArray alloc] init];
    settedRateArr = [[NSMutableArray alloc] init];
    timeArr = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    settedValue = [userDefaults integerForKey:SETTED_VALUE];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)readHeartbeatValue {
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:nil limit:1 sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (results.count > 0) {
            //打印查询结果
//            NSLog(@"resultCount = %ld result = %@", results.count, results);
            //把结果装换成字符串类型
            HKQuantitySample *result = results[0];
            HKQuantity *quantity = result.quantity;
            double heartbeatValue = ([quantity doubleValueForUnit:[HKUnit unitFromString:@"count/s"]] * 60);
            NSString *heartbeatStr = [NSString stringWithFormat:@"%f", heartbeatValue];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //查询是在多线程中进行的，如果要对UI进行刷新，要回到主线程中
//                NSLog(@"当前心律：%@",heartbeatStr);
                [heartRateArr addObject:heartbeatStr];
                [settedRateArr addObject:[NSString stringWithFormat:@"%ld", settedValue]];
                [timeArr addObject:@""];
                if (heartRateArr.count == 1) {
                    [self drawRateView];
                }
                if (heartRateArr.count > 1) {
                    [self updateRateView];
                }
                _currentValueLabel.text = [NSString stringWithFormat:@"%ld", [heartbeatStr integerValue]];
                [self setLabelColor:[heartbeatStr integerValue]];
            }];
        }
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}

- (void)setLabelColor:(NSUInteger)heartReat {
    if (heartReat > settedValue) {
        _currentValueLabel.textColor = [UIColor redColor];
        if (shakePhone) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    } else {
        _currentValueLabel.textColor = [UIColor colorWithRed:78/255.0 green:148/255.0 blue:7/255.0 alpha:1];
    }
}


- (IBAction)watchValue:(id)sender {
    if ([_watchValueButton.titleLabel.text isEqualToString:@"震动监控"]) {
        NSLog(@"");
        shakePhone = YES;
        [_watchValueButton setTitle:@"停止监控" forState:UIControlStateNormal];
        
    } else {
        NSLog(@"");
        shakePhone = NO;
        [_watchValueButton setTitle:@"震动监控" forState:UIControlStateNormal];
    }
}

- (IBAction)resetLineView:(id)sender {
}

- (IBAction)getLineImage:(id)sender {
}

- (void)drawRateView {
    [lineChart removeFromSuperview];
    lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 20, ScreenWidth * 3, 200.0)];
    [lineChart setXLabels:timeArr];
    PNLineChartData *data01 = [self heartRateData];
    PNLineChartData *data02 = [self settedRateData];
    lineChart.chartData = @[data01, data02];
    [lineChart strokeChart];
    _heartRateScrollView.contentSize = lineChart.bounds.size;
    [_heartRateScrollView addSubview:lineChart];
}

- (void)updateRateView {
    [lineChart removeFromSuperview];
    PNLineChartData *data01 = [self heartRateData];
    PNLineChartData *data02 = [self settedRateData];
    [lineChart setXLabels:timeArr];
    [lineChart updateChartData:@[data01, data02]];
    _heartRateScrollView.contentSize = lineChart.bounds.size;
    [_heartRateScrollView addSubview:lineChart];
    
}

- (PNLineChartData *)heartRateData {
    PNLineChartData *data01 = [PNLineChartData new];
    data01.color = PNFreshGreen;
    data01.itemCount = lineChart.xLabels.count;
    data01.getData = ^(NSUInteger index) {
        CGFloat yValue = [heartRateArr[index] floatValue];
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    return data01;
}

- (PNLineChartData *)settedRateData {
    PNLineChartData *data02 = [PNLineChartData new];
    data02.color = PNTwitterColor;
    data02.itemCount = lineChart.xLabels.count;
    data02.getData = ^(NSUInteger index) {
        CGFloat yValue = [settedRateArr[index] floatValue];
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    return data02;
}

@end
