//
//  HealthKitManage.h
//  Heartbeat
//
//  Created by pwnlc on 2016/11/24.
//  Copyright © 2016年 xyz.pwnlc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

@interface HealthKitManage : NSObject

@property (nonatomic, strong) HKHealthStore *healthStore;

@end
