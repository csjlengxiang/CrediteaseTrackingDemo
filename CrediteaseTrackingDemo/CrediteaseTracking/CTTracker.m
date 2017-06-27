//
//  CTTracker.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTTracker.h"
#import <CoreLocation/CoreLocation.h>
#import "CTDataStore.h"
#import "CTCommonValueUtils.h"
#import "CTDispatcher.h"
#import "CTTrackingKey.h"
#import "AFNetworking.h"
//#import "CommonUtils.h"
//#import "LiCaiAPI.h"

// 最大日志记录间隔
static NSTimeInterval const kMaxTrackingInterval        = 3 * 60 * 60;  // 3 hours

// 最小日志记录间隔
static NSTimeInterval const kMinTrackingInterval        = 3;            // 30 seconds

// 默认日志记录间隔
// static NSTimeInterval const kDefaultTrackingInterval    = 30 * 60;      // 30 minutes

// 最大会话空闲间隔
static long long const kMaxSessionIdleInterval          = 30 * 60;      // 30 minutes

// 批量发送日志数量
static NSInteger const kBatchSize                       = 100;          //TODO: change to reasonable value

@interface CTTracker () <CLLocationManagerDelegate>

@end

@implementation CTTracker {
    NSString *_appId;                       // 应用ID
    NSString *_channelId;                   // 渠道ID
    NSString *_currentPage;                 // 当前页
    NSString *_currentUser;                 // 当前用户
    NSString *_deviceId;                    // 设备ID
    CTDispatcher *_dispatcher;              // 发送实例
    CTTrackingSession *_currentSession;     // 当前会话
    CLLocationManager *_locationManager;    // 位置管理
    dispatch_queue_t _eventQueue;           // 发送线程
    NSTimer *_batchTimer;                   // 批量发送定时器
    BOOL _wifiOnly;                         // 是否只使用Wifi
}

// 唯一实例
+ (CTTracker *)sharedInstance {
    static CTTracker *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[CTTracker alloc] init];
    });
    return instance;
}

// 初始化
- (id)init {
    self = [super init];
    if (self) {
        [self setDispatchWifiOnly:NO];
        _eventQueue = dispatch_queue_create("com.creditease.tracking.eventq", DISPATCH_QUEUE_SERIAL);
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            NSLog(@"start location manager");
            _locationManager = [[CLLocationManager alloc] init];
            //_locationManager.delegate = self;
            //[_locationManager startMonitoringSignificantLocationChanges]; //TODO
        }
    }
    return self;
}

// 析构
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 设置发送间隔
- (void)setDispatchInterval:(NSTimeInterval)interval {
    NSLog(@"setDispatchInterval");
    if (interval < kMinTrackingInterval) {
        NSLog(@"set to minimal interval:%.0f", kMinTrackingInterval);
        interval = kMinTrackingInterval;
    }
    if (interval > kMaxTrackingInterval) {
        NSLog(@"set to maximum interval:%.0f", kMaxTrackingInterval);
        interval = kMaxTrackingInterval;
    }
    if (_batchTimer)
        [_batchTimer invalidate];
    _batchTimer = [NSTimer timerWithTimeInterval:interval
                                          target:self
                                        selector:@selector(onBatchTimerFired:)
                                        userInfo:nil
                                         repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:_batchTimer forMode:NSDefaultRunLoopMode];
    [_batchTimer fire];
}

// 设置是否仅用Wifi
- (void)setDispatchWifiOnly:(BOOL)wifiOnly {
    _wifiOnly = wifiOnly;
}

// 设置应用ID和渠道ID
- (void)setAppId:(NSString *)appId channelId:(NSString *)channelId {
    _appId = [appId copy];
    _channelId = [channelId copy];
    [self checkLastSession];
    if (_dispatcher) {
        [_dispatcher setAppId:_appId];
    } else {
        _dispatcher = [[CTDispatcher alloc] initWithAppId:_appId];
    }
}

// 设置用户ID
- (void)setUserId:(NSString *)userId {
    _currentUser = userId;
}

// 设置设备ID
- (void)setDeviceId:(NSString *)deviceId {
    _deviceId = deviceId;
}

// 检查最近的会话
- (void)checkLastSession {
    NSLog(@"checkLastSession");
    dispatch_async(_eventQueue, ^{
        CTTrackingSession *lastSession = [[CTDataStore sharedInstance] getLastSession];
        if (lastSession) {
            NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
            unsigned long long ts = (unsigned long long)(timestamp * 1000);
            long long idle = ts - lastSession.lactAct.longLongValue;
            NSLog(@"idletime:%lld", idle);
            if (idle > kMaxSessionIdleInterval * 1000) {
                [self trackSessionEnd:lastSession];
                [self trackSessionBegin:[NSNumber numberWithLongLong:idle]];
            } else {
                _currentSession = lastSession;
                NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
                unsigned long long ts = (unsigned long long)(timestamp * 1000);
                [[CTDataStore sharedInstance] updateSessionLastActivity:lastSession timestamp:[NSNumber numberWithLongLong:ts]];
            }
        } else {
            [self trackSessionBegin:[NSNumber numberWithLongLong:0]];
        }
    });
}

// 应用状态发生改变时调用
- (void)onResignActive {
    NSLog(@"onResignActive");
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    unsigned long long ts = (unsigned long long)(timestamp * 1000);
    dispatch_async(_eventQueue, ^{
        [[CTDataStore sharedInstance] updateSessionLastActivity:_currentSession timestamp:[NSNumber numberWithLongLong:ts]];
    });
    [self onBatchTimerFired:nil];
}

// 触发批量发送操作
- (void)onBatchTimerFired:(NSTimer *)timer {
    NSLog(@"onBatchTimerFired");
    dispatch_async(_eventQueue, ^{
        if ([self isAllowDispatch] && _dispatcher) {
            NSArray *events = [[CTDataStore sharedInstance] getEventsForUpload:kBatchSize];
            if (events != nil && events.count > 0) {
                [_dispatcher dispatchBatchEvents:events
                                         session:_currentSession
                                         success:^{
                                             dispatch_async(_eventQueue, ^{
                                                 [[CTDataStore sharedInstance] deleteEvents:events];
                                             });
                                         }
                                         failure:^{
                                             dispatch_async(_eventQueue, ^{
                                                 [[CTDataStore sharedInstance] setState:CTEventStateUploadFailed forEvents:events];
                                             });
                                         }];
            }
        }
    });
}

// 发送实时事件
- (void)sendEvent:(NSString *)eventType label:(NSString *)label parameters:(NSDictionary *)params {
    NSLog(@"sendEvent");
    CTTrackingEvent *ev = [self createPlaceholderEvent:eventType];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic addEntriesFromDictionary:[self getEventCommonParameters]];
    if (label && label.length > 0)
        dic[kCTLabel] = label;
    dispatch_async(_eventQueue, ^{
        dic[kCTSessionId] = _currentSession.sid;
        if (![dic objectForKey:@"page"] || [[dic objectForKey:@"page"] isEqualToString:@""]) {
            dic[kCTPage] = _currentPage ? _currentPage : @"unknown";
        }
        ev.values = dic;
        CTTrackingSession *capturedSession = _currentSession;
        if ([self isAllowDispatch] && _dispatcher) {
            [_dispatcher dispatchRealtimeEvent:ev
                                       session:capturedSession
                                       success:nil
                                       failure:^{
                                           [[CTDataStore sharedInstance] insertEvent:ev inSession:capturedSession updateSession:YES];
                                       }];
        } else {
            [[CTDataStore sharedInstance] insertEvent:ev inSession:capturedSession updateSession:YES];
        }
    });
}

// 记录事件信息
- (void)trackEvent:(NSString *)eventType label:(NSString *)label parameters:(NSDictionary *)params {
    CTTrackingEvent *ev = [self createPlaceholderEvent:eventType];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
    [dic addEntriesFromDictionary:[self getEventCommonParameters]];
    if (label && label.length > 0)
        dic[kCTLabel] = label;
    dispatch_async(_eventQueue, ^{
        dic[kCTSessionId] = _currentSession.sid;
        dic[kCTPage] = _currentPage ? _currentPage : @"unknown";
        ev.values = dic;
        [[CTDataStore sharedInstance] insertEvent:ev inSession:_currentSession updateSession:YES];
    });
}

// 记录页面开始
- (void)trackPageBegin:(NSString *)pageName {
    NSLog(@"trackPageBegin");
    CTTrackingEvent *ev = [self createPlaceholderEvent:kCTPageLoad];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic addEntriesFromDictionary:[self getEventCommonParameters]];
    dic[kCTPage] = pageName ? pageName : @"unknown";
    dic[@"referrer"]  = self.lastPageName ? self.lastPageName : @"";
    self.lastPageName = pageName ? pageName : @"";
    dispatch_async(_eventQueue, ^{
        _currentPage = pageName;
        dic[kCTSessionId] = _currentSession.sid;
        ev.values = dic;
        [[CTDataStore sharedInstance] insertEvent:ev inSession:_currentSession updateSession:YES];
    });
}

- (void)setPageName:(NSString *)pageName{
    _currentPage = pageName ? pageName : @"";
    self.lastPageName = pageName ? pageName : @"";
}

// 记录页面结束
- (void)trackPageEnd:(NSString *)pageName duration:(NSTimeInterval)duration {
    NSLog(@"trackPageEnd");
    CTTrackingEvent *ev = [self createPlaceholderEvent:kCTPageEnd];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic addEntriesFromDictionary:[self getEventCommonParameters]];
    dic[kCTPage] = pageName ? pageName : @"unknown";
    dic[kCTDuration] = [NSString stringWithFormat:@"%.3f", duration];
    dispatch_async(_eventQueue, ^{
        dic[kCTSessionId] = _currentSession.sid;
        ev.values = dic;
        [[CTDataStore sharedInstance] insertEvent:ev inSession:_currentSession updateSession:YES];
    });
}

// 开始新的会话
- (void)startNewSession {
    NSLog(@"startNewSession");
    dispatch_async(_eventQueue, ^{
        if (_currentSession)
            [self trackSessionEnd:_currentSession];
        [self trackSessionBegin:[NSNumber numberWithLongLong:0]];
    });
}

#pragma mark - Functions

// 是否允许发送事件
- (BOOL)isAllowDispatch {
    if (_wifiOnly) {
        if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusReachableViaWiFi) {
            NSLog(@"dispatch wifi only");
            return NO;
        }
    }
    return YES;
}

// 开始记录会话
- (void)trackSessionBegin:(NSNumber *)idle {
    NSLog(@"trackSessionBegin");
    CTTrackingSession *session = [self createPlaceholderSession];
    session.values = [self getCommonParameters];
    CTTrackingEvent *ev = [self createPlaceholderEvent:kCTSessionStart];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic addEntriesFromDictionary:[self getEventCommonParameters]];
    [[CTDataStore sharedInstance] insertSession:session];
    _currentSession = session;
    dic[kCTSessionId] = _currentSession.sid;
    dic[kCTSessionIdleTime] = idle;
    ev.values = dic;
    [[CTDataStore sharedInstance] insertEvent:ev inSession:session updateSession:NO];
}

// 结束记录会话
- (void)trackSessionEnd:(CTTrackingSession *)session {
    NSLog(@"trackSessionEnd");
    if (session) {
        CTTrackingEvent *ev = [self createPlaceholderEvent:kCTSessionEnd];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic addEntriesFromDictionary:[self getEventCommonParameters]];
        long long duration = session.lactAct.longLongValue - session.timestamp.longLongValue;
        dic[kCTDuration] = [NSString stringWithFormat:@"%lld", duration];
        dic[kCTSessionId] = session.sid;
        ev.values = dic;
        [[CTDataStore sharedInstance] insertEvent:ev inSession:session updateSession:NO];
    }
}

// 创建事件
- (CTTrackingEvent *)createPlaceholderEvent:(NSString *)type {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    unsigned long long ts = (unsigned long long)(timestamp * 1000);
    CTTrackingEvent *ev = [[CTTrackingEvent alloc] init];
    ev.type = type;
    ev.timestamp = [NSNumber numberWithLongLong:ts];
    return ev;
}

// 创建会话
- (CTTrackingSession *)createPlaceholderSession {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    unsigned long long ts = (unsigned long long)(timestamp * 1000);
    CTTrackingSession *session = [[CTTrackingSession alloc] init];
    session.timestamp = [NSNumber numberWithLongLong:ts];
    return session;
}

// 获得通用参数
- (NSDictionary *)getCommonParameters {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[kCTGuid] = _deviceId ? _deviceId : [CTCommonValueUtils getGuid];
    params[kCTScreentResolution] = [CTCommonValueUtils getScreenResolution];
    params[kCTAppVersion] = [CTCommonValueUtils getAppVersion];
    params[kCTAppBuild] = [CTCommonValueUtils getAppBuild];
    if (_channelId)
        params[kCTChannelId] = _channelId;
    params[kCTOSVersion] = [CTCommonValueUtils getOSVersion];
    params[kCTBrand] = @"Apple";
    params[kCTModelName] = [CTCommonValueUtils getDeviceModel];
    params[kCTPhoneName] = [CTCommonValueUtils getDeviceName];
    params[KCTCarrier] = [CTCommonValueUtils getNetworkCarrier];
    return params;
}

// 获得事件通用参数
- (NSDictionary *)getEventCommonParameters {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    if (_locationManager) {
        CLLocation *loc = _locationManager.location;
        if (loc) {
            dic[kCTLatLong] = [NSString stringWithFormat:@"(%f,%f)", loc.coordinate.latitude, loc.coordinate.longitude];
        } else {
            //NSLog(@"no location");
        }
    }
    dic[kCTNetwork] = [CTCommonValueUtils getNetworkReachability];
    dic[kCTWifiSsid] = [CTCommonValueUtils getWifiSSID];
    
    dic[kCTAppVersion] = [CTCommonValueUtils getAppVersion];
    dic[kCTAppBuild] = [CTCommonValueUtils getAppBuild];
    if (_currentUser) {
        dic[kCTUserId] = _currentUser;
    }
    return dic;
}

#pragma mark - LocationManager Delegate

// 已经更新位置
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"didUpdateLocations");
}

@end
