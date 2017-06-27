//
//  CTTrackingKey.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#ifndef CrediteaseTracking_CTTrackingKey_h
#define CrediteaseTracking_CTTrackingKey_h

// 事件类型
static NSString * const kCTPageLoad             = @"pageload";          // 页面加载
static NSString * const kCTSessionStart         = @"session";           // 会话开始
static NSString * const kCTSessionEnd           = @"sessionend";        // 会话结束
//static NSString * const kCTPageStart          = @"pagestart";         // 页面开始
static NSString * const kCTPageEnd              = @"pageend";           // 页面结束

// 传递值的名称
static NSString * const kCTLabel                = @"label";             // 标签
static NSString * const kCTPage                 = @"page";              // 页面
static NSString * const kCTSessionId            = @"sessionid";         // 会话ID
static NSString * const kCTSessionIdleTime      = @"idletime";          // 会话闲置时间

// 环境信息
static NSString * const kCTGuid                 = @"guid";              // GUID
static NSString * const kCTUserId               = @"userid";            // 用户ID
static NSString * const kCTScreentResolution    = @"screenresolution";  // 屏幕分辨率
static NSString * const kCTLatLong              = @"latlong";           // 经纬度
static NSString * const kCTAppVersion           = @"appversion";        // 应用版本号
static NSString * const kCTAppBuild             = @"appbuild";          // 应用Build号
static NSString * const kCTNetwork              = @"network";           // 网络类型
static NSString * const kCTWifiSsid             = @"wifissid";          // 当前Wifi的SSID
static NSString * const kCTChannelId            = @"channelid";         // 渠道号
static NSString * const kCTOSVersion            = @"os";                // 操作系统
static NSString * const kCTBrand                = @"brand";             // 品牌，Apple
static NSString * const kCTModelName            = @"modelname";         // 设备类型
static NSString * const kCTPhoneName            = @"friendlyname";      // 设备名称
static NSString * const KCTCarrier              = @"carrier";           // 网络运营商
static NSString * const kCTDuration             = @"duration";          // 持续时间

#endif
