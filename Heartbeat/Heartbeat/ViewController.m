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
    NSInteger highestRate;
    NSInteger sumCount;
    NSInteger overCount;
    float rateOverPercent;
    
}
@property (nonatomic, strong) HKHealthStore *healthStore;

@end

@implementation ViewController
@synthesize currentValueLabel = _currentValueLabel;
@synthesize watchValueButton = _watchValueButton;
@synthesize heartRateScrollView = _heartRateScrollView;
@synthesize highestRateLabel = _highestRateLabel;
@synthesize percentOverLine = _percentOverLine;

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
    
    highestRate = 0;
    sumCount = 0;
    overCount = 0;
    
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
                // 设置并显示最高心率
                if (highestRate == 0) {
                    highestRate = heartbeatStr.integerValue;
                    _highestRateLabel.text = [NSString stringWithFormat:@"%ld", highestRate];
                } else {
                    if (highestRate < heartbeatStr.integerValue) {
                        highestRate = heartbeatStr.integerValue;
                        _highestRateLabel.text = [NSString stringWithFormat:@"%ld", highestRate];
                    }
                }
                // 设置显示超过比例
                sumCount = sumCount + 1;
                if (heartbeatStr.integerValue > settedValue) {
                    overCount = overCount + 1;
                }
                rateOverPercent = (overCount*1.0)/(sumCount*1.0);
                NSLog(@"overCount = %ld; sumCount = %ld", overCount, sumCount);
                NSLog(@"rateOverPercent = %f", rateOverPercent);
                _percentOverLine.text = [NSString stringWithFormat:@"%.1f%s", rateOverPercent * 100, "%"];
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
    // 重置所有属性
    [self drawRateView];
    highestRate = 0;
    sumCount = 0;
    overCount = 0;
    [heartRateArr removeAllObjects];
    [timeArr removeAllObjects];
    [settedRateArr removeAllObjects];
    _percentOverLine.text = @"0%";
    _highestRateLabel.text = @"0";
}

- (IBAction)getLineImage:(id)sender {
    UIGraphicsBeginImageContextWithOptions([self getSavedImage].bounds.size, YES, 1);
    [[self getSavedImage].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *imageWantToSave = UIGraphicsGetImageFromCurrentImageContext();
    UIImageWriteToSavedPhotosAlbum(imageWantToSave, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    UIGraphicsEndImageContext();
    lineChart.frame = CGRectMake(0, 20, lineChart.bounds.size.width, 200);
}

- (UIView *)getSavedImage {
    UIView *viewWantToSave = [[UIView alloc] initWithFrame:CGRectMake(0, 0, lineChart.bounds.size.width, lineChart.bounds.size.width)];
    viewWantToSave.backgroundColor = [UIColor whiteColor];
    lineChart.frame = CGRectMake(0, 250, lineChart.bounds.size.width, lineChart.bounds.size.height);
    [viewWantToSave addSubview:lineChart];
    
    UILabel *dateLabele = [[UILabel alloc] init];
    dateLabele.font = [UIFont systemFontOfSize:18 weight:UIFontWeightLight];
    NSString *str = [self getCurrentTime];
    dateLabele.text = str;
    dateLabele.textColor = [UIColor darkGrayColor];
    dateLabele.numberOfLines = 1;
    dateLabele.lineBreakMode = NSLineBreakByTruncatingTail;
    CGSize maximumLabelSize = CGSizeMake(100, 9999);
    CGSize expectSize = [dateLabele sizeThatFits:maximumLabelSize];
    dateLabele.frame = CGRectMake(lineChart.bounds.size.width - expectSize.width - 20, lineChart.bounds.size.width - expectSize.height - 30, expectSize.width, expectSize.height);
    [viewWantToSave addSubview:dateLabele];
    
    UILabel *scoreLabele = [[UILabel alloc] init];
    scoreLabele.font = [UIFont systemFontOfSize:18 weight:UIFontWeightLight];
    NSString *scoreStr = [NSString stringWithFormat:@"%ld / %ld / %@", settedValue, highestRate, [NSString stringWithFormat:@"%.1f%s", rateOverPercent * 100, "%"]];
    scoreLabele.text = scoreStr;
    scoreLabele.textColor = [UIColor darkGrayColor];
    scoreLabele.numberOfLines = 1;
    scoreLabele.lineBreakMode = NSLineBreakByTruncatingTail;
    CGSize scoreExpectSize = [scoreLabele sizeThatFits:maximumLabelSize];
    scoreLabele.frame = CGRectMake(dateLabele.frame.origin.x - scoreExpectSize.width - 50, lineChart.bounds.size.width - expectSize.height - 30, scoreExpectSize.width, scoreExpectSize.height);
    [viewWantToSave addSubview:scoreLabele];
    
    return viewWantToSave;
}

- (NSString *)getCurrentTime {
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY/MM/dd hh:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    return dateString;
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存失败" ;
    }else{
        msg = @"保存成功" ;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认"style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)drawRateView {
    [lineChart removeFromSuperview];
    lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 20, ScreenWidth * 2, 200.0)];
    lineChart.chartMarginTop = 30.0;
    [lineChart setXLabels:timeArr];
    PNLineChartData *data01 = [self heartRateData];
    PNLineChartData *data02 = [self settedRateData];
    lineChart.chartData = @[data01, data02];
    [lineChart strokeChart];
    _heartRateScrollView.contentSize = lineChart.bounds.size;
    [_heartRateScrollView addSubview:lineChart];
    [_heartRateScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)updateRateView {
    [lineChart removeFromSuperview];
    PNLineChartData *data01 = [self heartRateData];
    PNLineChartData *data02 = [self settedRateData];
    [lineChart setXLabels:timeArr];
    [lineChart updateChartData:@[data01, data02]];
    _heartRateScrollView.contentSize = lineChart.bounds.size;
    [_heartRateScrollView addSubview:lineChart];
    if (heartRateArr.count > 15) {
        [_heartRateScrollView setContentOffset:CGPointMake(ScreenWidth, 0) animated:YES];
    }
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
