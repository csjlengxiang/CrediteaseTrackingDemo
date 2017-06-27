//
//  TrackingManager.h
//  DianDianLiCai
//
//  Created by robin on 15/1/8.
//  Copyright (c) 2015年 Creditease. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kGACategoryButton;
extern NSString * const kGACategoryBanner;
extern NSString * const kGACategoryPopup;
extern NSString * const kGACategoryAlert;
extern NSString * const kGACategoryPage;
extern NSString * const kGACategoryWebpage;
extern NSString * const kGACategoryError;

extern NSString * const kGAActionClick;
extern NSString * const kGAActionRefresh;
extern NSString * const kGAActionConfirm;
extern NSString * const kGAActionCancel;
extern NSString * const kGAActionClose;
extern NSString * const kGAActionShow;
extern NSString * const kGAActionDismiss;
extern NSString * const kGAActionRegisterPush;
extern NSString * const kGAActionLaunch;
extern NSString * const kGAActionPushOpen;
extern NSString * const kGAActionShare;
extern NSString * const kGAActionShareResult;
extern NSString * const kGAActionInput;
extern NSString * const kGAActionRealName;
extern NSString * const kGAActionReCheck;
extern NSString * const kGAActionGuidCreate;
@interface TrackingManager : NSObject

+ (instancetype)sharedInstance;

// use set app id
+ (void)setAppID:(NSString *)appID guid:(NSString *)guid;

- (void)setup;
- (void)trackUserId:(NSInteger)userId;
- (void)trackScreen:(NSString *)screenName;
- (void)trackScreenEnd:(NSString *)screenName Duraion:(NSTimeInterval)duration;
- (void)trackTiming:(NSString *)category interval:(NSTimeInterval)interval name:(NSString *)name label:(NSString *)label;
- (void)trackEvent:(NSString *)category action:(NSString *)action label:(NSString *)label screen:(NSString *)screen;
- (void)trackEvent:(NSString *)category action:(NSString *)action url:(NSString *)url urlType:(NSString *)urltype screen:(NSString *)screen;
- (void)trackRealtimeEvent:(NSString *)name label:(NSString *)label param:(NSDictionary *)param;
- (void)trackEvent:(NSString *)category action:(NSString *)action params:(NSDictionary *)params screen:(NSString *)screen;
- (void)resetScreen;

- (void)trackClick:(NSString *)label;
- (void)trackClick:(NSString *)label param:(NSDictionary *)parameters;

- (void)trackRealtimeEventNow;

@end
