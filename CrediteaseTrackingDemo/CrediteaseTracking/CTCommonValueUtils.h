//
//  CTCommonValueUtils.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import <Foundation/Foundation.h>

// GUID存放在NSUserDefaults中的键值
static NSString * kDefaultGuid = @"com.creditease.tracking.guid";

// 运行环境信息收集类
@interface CTCommonValueUtils : NSObject

+ (NSString *)getGuid;

+ (NSString *)getScreenResolution;

+ (NSString *)getAppVersion;

+ (NSString *)getAppBuild;

+ (NSString *)getNetworkReachability;

+ (NSString *)getWifiSSID;

+ (NSString *)getOSVersion;

+ (NSString *)getDeviceModel;

+ (NSString *)getDeviceName;

+ (NSString *)getNetworkCarrier;

@end
