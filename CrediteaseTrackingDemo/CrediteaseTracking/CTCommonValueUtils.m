//
//  CTCommonValueUtils.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTCommonValueUtils.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/utsname.h>
#import "AFNetworking.h"
//#import "babysleep-Swift.h"
#import "CTTracker.h"

@implementation CTCommonValueUtils


// 获得生成的GUID，如"9F5B91A363BB4F4C8AA709C30B2E112E"
+ (NSString *)getGuid {
//    NSString * idfa = [IDFA IDFA];
    [[CTTracker sharedInstance] setDeviceId:kDefaultGuid];
    return kDefaultGuid;
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSString *guid = [userDefaults stringForKey:kDefaultGuid];
//    if (!guid) {
//        //CFUUIDRef uuidObj = CFUUIDCreate(nil);
//        //NSString *guid = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
//        UIDevice *device = [UIDevice currentDevice];
//        NSString *guid = [[device identifierForVendor] UUIDString];
//        
//        [userDefaults setObject:guid forKey:kDefaultGuid];
//        [userDefaults synchronize];
//        //CFRelease(uuidObj);
//        //    [[CTTracker sharedInstance] setDeviceId:deviceId];
//    }
//    return guid;//[guid stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

// 获得屏幕分辨率，如"640*960"
+ (NSString *)getScreenResolution {
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
    return [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
}

// 获得应用版本号
+ (NSString *)getAppVersion {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return version != nil ? version : @"unknown";
}

// 获得应用Build号
+ (NSString *)getAppBuild {
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return build != nil ? build : @"unknown";
}

// 获得网络状态
+ (NSString *)getNetworkReachability {
    switch ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus) {
        case AFNetworkReachabilityStatusNotReachable:
            return @"no_network";
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return @"wifi";
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return @"cellular";
        case AFNetworkReachabilityStatusUnknown:
        default:
            return @"unknown";
    }
}

// 获得当前Wifi的SSID
// http://stackoverflow.com/questions/31555640/how-to-get-wifi-ssid-in-ios9-after-captivenetwork-is-depracted-and-calls-for-wif
// 貌似gg了
// 关闭这个警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSString *)getWifiSSID {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSDictionary *info = nil;
    for (NSString *ifname in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        if (info && [info count]) {
            return info[@"SSID"];
        }
    }
    return @"unknown";
}

#pragma clang diagnostic pop

// 获得系统版本号
+ (NSString *)getOSVersion {
    return [NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
}

// 获得设备类型
+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

// 获得设备名称
+ (NSString *)getDeviceName {
    return [UIDevice currentDevice].name;
}

// 获得网络运营商
+ (NSString *)getNetworkCarrier {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return carrier.carrierName ? carrier.carrierName : @"unknown";
}

@end
