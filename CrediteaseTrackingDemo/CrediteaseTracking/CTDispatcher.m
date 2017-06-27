//
//  CTDispatcher.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTDispatcher.h"
#import "CTTrackingHelper.h"
#import <AFNetworking/AFNetworking.h>
#import "AFHTTPSessionManager.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "CTCommonValueUtils.h"

//#import <AdSupport/AdSupport.h>
//#import "LiCaiAPI.h"


/* -- API地址和路径 -- */
static NSString * const HOST            = @"http://t1.bdp.yixin.com/%@";
static NSString * const PATH_REALTIME   = @"/%@";
static NSString * const PATH_BATCH      = @"/batch";

@implementation CTDispatcher {
    NSString *_appId;       // 应用ID
    NSString *_realtimeUrl; // 实时日志API地址
    NSString *_batchUrl;    // 批量日志API地址
}

// 使用应用ID初始化
- (id)initWithAppId:(NSString *)appId {
    self = [super init];
    if (self) {
        _appId = appId;
        [self generateUrls];
    }
    return self;
}

// 设置应用ID
- (void)setAppId:(NSString *)appId {
    _appId = appId;
    [self generateUrls];
}

// 生成实时日志和批量日志的API地址
- (void)generateUrls {
    NSString *endPoint = [NSString stringWithFormat:HOST, _appId];
    _realtimeUrl = [endPoint stringByAppendingString:PATH_REALTIME];
    _batchUrl = [endPoint stringByAppendingString:PATH_BATCH];
}

// 发送实时日志事件或会话
- (void)dispatchRealtimeEvent:(CTTrackingEvent *)event session:(CTTrackingSession *)session success:(void (^)(void))success failure:(void (^)(void))failure {
    NSLog(@"dispatchRealtimeEvent");
    
    // config
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 20;
    
    AFHTTPSessionManager * manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    
    // accept type
    NSMutableSet *newJsonSet = [NSMutableSet setWithSet:manager.responseSerializer.acceptableContentTypes];
    [newJsonSet addObject:@"text/plain"];
    [newJsonSet addObject:@"application/x-www-form-urlencoded"];
    [newJsonSet addObject:@"image/gif"];

    manager.responseSerializer.acceptableContentTypes = newJsonSet;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:event.values];
    [params addEntriesFromDictionary:session.values];
    params[@"localts"] = event.timestamp;
    
    
    [manager GET:[NSString stringWithFormat:_realtimeUrl, event.type]
      parameters:params
         progress:^(NSProgress * _Nonnull downloadProgress) {
             // do nothing
         }
         success:^(NSURLSessionDataTask *task, id responseObject) {
             if (success)
                 success();
         }
         failure:^(NSURLSessionDataTask *task, NSError *error) {
             // NSLog(@"%@", error.localizedDescription);
             if (error.code == 3840) { // 特判
                 if (success) {
                     success();
                 }
             } else if (failure) {
                 failure();
             }
         }];
}

// 发送批量日志事件或会话
- (void)dispatchBatchEvents:(NSArray *)events session:(CTTrackingSession *)session success:(void (^)(void))success failure:(void (^)(void))failure {
    if (session.values[@"guid"] == nil) {
        NSMutableDictionary *tempValues = [NSMutableDictionary dictionaryWithDictionary:session.values];
        tempValues[@"guid"] = [CTCommonValueUtils getGuid];//[[[ASIdentifierManager sharedManager]advertisingIdentifier]UUIDString];
        session.values = tempValues;
    }

    NSLog(@"dispatchBatchEvents");

    NSMutableArray *trackings = [[NSMutableArray alloc] initWithCapacity:[events count]];
    NSMutableArray *logtrackings = [[NSMutableArray alloc] initWithCapacity:[events count]];
    int numberofevents = 0;
    for (CTTrackingEvent *ev in events) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:ev.values];
        dic[@"seq"] = ev.eid;
        dic[@"localts"] = ev.timestamp;
        NSString *valueStr = [self queryStringFromDictionary:dic];
        NSString *trackingStr = [NSString stringWithFormat:@"%@?%@", [self encodeUrlString:ev.type], valueStr];
        
        [trackings addObject:trackingStr];
        
        NSMutableDictionary *logtracking = [NSMutableDictionary dictionaryWithDictionary:ev.values];
        logtracking[@"seq"] = ev.eid;
        logtracking[@"localts"] = ev.timestamp;
        logtracking[@"type"] = ev.type;
        NSLog(@"type = %@",logtracking[@"type"]);
        NSLog(@"page = %@",logtracking[@"page"]);
        NSLog(@"label = %@",logtracking[@"label"]);
        NSLog(@"%@",logtracking);
        [logtrackings addObject:logtracking];
        numberofevents += 1;
    }
    NSLog(@"%d",numberofevents);
    NSString *common = [self queryStringFromDictionary:session.values];
    NSLog(@"%@",common);
    NSDictionary *dic = @{@"common": common,
                          @"trackings": trackings};
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 20;
    
    AFHTTPSessionManager * manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    
    // accept type
    NSMutableSet *newJsonSet = [NSMutableSet setWithSet:manager.responseSerializer.acceptableContentTypes];
    [newJsonSet addObject:@"text/plain"];
    [newJsonSet addObject:@"application/x-www-form-urlencoded"];
    [newJsonSet addObject:@"image/gif"];
    
    manager.responseSerializer.acceptableContentTypes = newJsonSet;
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"DianDianLiCai/2 CFNetwork/758.3.15 Darwin/15.5.0" forHTTPHeaderField:@"User-Agent"];
    [manager.requestSerializer setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
    
    [manager POST:_batchUrl parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        // do nothing
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success();
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure();
        }
    }];
}

// 根据dic生成参数字符串，格式为k1=v1&k2=v2&...&kn=vn
- (NSString *)queryStringFromDictionary:(NSDictionary *)dic {
    NSMutableString *query = [[NSMutableString alloc] init];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [query appendFormat:@"%@=%@&", [self encodeUrlString:((NSObject *)key).description], [self encodeUrlString:((NSObject *)obj).description]];
    }];
    if (query.length > 0) {
        [query replaceCharactersInRange:NSMakeRange(query.length - 1, 1) withString:@""];
    }
    return query;
}

// 用UTF8编码指定字符串
- (NSString *)encodeUrlString:(NSString *)unencodedString {
    return [unencodedString stringByRemovingPercentEncoding];
}

@end
