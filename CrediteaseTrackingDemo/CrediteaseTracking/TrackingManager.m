//
//  TrackingManager.m
//  DianDianLiCai
//
//  Created by robin on 15/1/8.
//  Copyright (c) 2015年 Creditease. All rights reserved.
//

#import "TrackingManager.h"
#import "CTTracker.h"
#import "CTCommonValueUtils.h"

#ifdef DEBUG 
static NSString * kCTTrackerAppId = @"babysleeptest";
#else
static NSString * kCTTrackerAppId = @"babysleep";
#endif

NSString * const kGACategoryButton      = @"Button";
NSString * const kGACategoryBanner      = @"Banner";
NSString * const kGACategoryPopup       = @"Popup";
NSString * const kGACategoryAlert       = @"Alert";
NSString * const kGACategoryPage        = @"Page";
NSString * const kGACategoryError       = @"Error";
NSString * const kGACategoryWebpage     = @"Webpage";
NSString * const kGAActionClick         = @"click";
NSString * const kGAActionRefresh       = @"Refresh";
NSString * const kGAActionConfirm       = @"Confirm";
NSString * const kGAActionCancel        = @"Cancel";
NSString * const kGAActionClose         = @"Close";
NSString * const kGAActionShow          = @"Show";
NSString * const kGAActionDismiss       = @"Dismiss";
NSString * const kGAActionRegisterPush  = @"RegisterPush";
NSString * const kGAActionLaunch        = @"Launch";
NSString * const kGAActionPushOpen      = @"pushopen";
NSString * const kGAActionShare         = @"share";
NSString * const kGAActionShareResult   = @"shareresult";
NSString * const kGAActionInput         = @"input";
NSString * const kGAActionRealName      = @"realname";
NSString * const kGAActionReCheck       = @"recheck";
NSString * const kGAActionGuidCreate    = @"guidcreate";

@implementation TrackingManager

+ (instancetype)sharedInstance {
    static TrackingManager *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[TrackingManager alloc] init];
        [instance setup];
    });
    return instance;
}

+ (void)setAppID:(NSString *)appID guid:(NSString *)guid {
    kCTTrackerAppId = appID;
    kDefaultGuid = guid;
}

- (void)setup {
    [[CTTracker sharedInstance] setAppId:kCTTrackerAppId channelId:@"iOS"];
    [[CTTracker sharedInstance] setDispatchInterval:300];
}

- (void)trackUserId:(NSInteger)userId {
    if (userId > 0) {
        [[CTTracker sharedInstance] setUserId:[NSString stringWithFormat:@"%ld", (long)userId]];
    }
    else {
        [[CTTracker sharedInstance] setUserId:nil];
    }
}

- (void)trackScreen:(NSString *)screenName {
    [[CTTracker sharedInstance] trackPageBegin:screenName];
}

- (void)trackScreenEnd:(NSString *)screenName Duraion:(NSTimeInterval)duration{
    [[CTTracker sharedInstance] trackPageEnd:screenName duration:duration];
}

/*
 * only used for tracking api
 */
- (void)trackTiming:(NSString *)category interval:(NSTimeInterval)interval name:(NSString *)name label:(NSString *)label {
    NSString *eventName = [name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString *eventLabel = [NSString stringWithFormat:@"%@_%@", label, [self getTimeIntervalString:interval]];
    [[CTTracker sharedInstance] trackEvent:@"API" label:eventLabel parameters:@{@"api":eventName}];
}

- (void)trackEvent:(NSString *)category action:(NSString *)action label:(NSString *)label screen:(NSString *)screen {
    [[CTTracker sharedInstance] trackEvent:action label:label parameters:nil];
}

- (void)trackClick:(NSString *)label {
    // NSLog(@"%@ click page ", label);
    [[CTTracker sharedInstance] trackEvent:kGAActionClick label:label parameters:nil];
}

- (void)trackClick:(NSString *)label param:(NSDictionary *)parameters {
    // NSLog(@"%@ click page ", label);
    [[CTTracker sharedInstance] trackEvent:kGAActionClick label:label parameters:parameters];
}

- (void)resetScreen {
    [[CTTracker sharedInstance] setPageName:nil];
}

- (void)trackEvent:(NSString *)category action:(NSString *)action params:(NSDictionary *)params screen:(NSString *)screen {
    [[CTTracker sharedInstance] trackEvent:action label:nil parameters:params];
}

- (void)trackEvent:(NSString *)category action:(NSString *)action url:(NSString *)url urlType:(NSString *)urltype screen:(NSString *)screen {
    [[CTTracker sharedInstance] trackEvent:action label:url parameters:@{@"urltype":urltype}];
}

- (void)trackRealtimeEvent:(NSString *)name label:(NSString *)label param:(NSDictionary *)param {
    [[CTTracker sharedInstance] sendEvent:name label:label parameters:param];
}

- (void)trackRealtimeEventNow {
    [[CTTracker sharedInstance] onBatchTimerFired:nil];
}

#pragma mark - Function
- (NSString *)getTimeIntervalString:(NSTimeInterval)interval {
    if (interval <= 2.0) {
        return [NSString stringWithFormat:@"%.0f00ms", ceil(interval * 10)];
    } else if (interval <= 10.0) {
        double fraction = interval - floor(interval);
        if (fraction <= 0.5)
            return [NSString stringWithFormat:@"%.0f500ms", floor(interval)];
        else
            return [NSString stringWithFormat:@"%.0f000ms", ceil(interval)];
    } else {
        return @"gt10s";
    }
}

@end
