//
//  CTTracker.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 日志系统接口类
 */
@interface CTTracker : NSObject

@property NSString *lastPageName;

+ (CTTracker *)sharedInstance;

/** Set tracking AppId and ChannelId
 
 @param appId       tracking AppId
 @param channelId   tracking ChannelId
 */
- (void)setAppId:(NSString *)appId channelId:(NSString *)channelId;

/** Set tracking data dispatch interval. Default interval is 30 minutes.
 
 @param interval    tracking interval
 */
- (void)setDispatchInterval:(NSTimeInterval)interval;

/** Set dispatch tracking data only with wifi available
 
 @param wifiOnly    dispatch only with wifi available
 */
- (void)setDispatchWifiOnly:(BOOL)wifiOnly;

/** Set user id 
 
 @param userId      user id
 */
- (void)setUserId:(NSString *)userId;

/** Set device id
 
 @param deviceId    device id
 */
- (void)setDeviceId:(NSString *)deviceId;

/** Send a tracking event immediately
 
 @param eventType   event type
 @param label       event label
 @param parameters  event parameters
 */
- (void)sendEvent:(NSString *)eventType label:(NSString *)label parameters:(NSDictionary *)params;

/** Track an event. Will batch send in background with specified interval
 
 @param eventType   event type
 @param label       event label
 @param parameters  event parameters
 */
- (void)trackEvent:(NSString *)eventType label:(NSString *)label parameters:(NSDictionary *)params;

/** Track page begin
 
 @param pageName    page name
 */
- (void)trackPageBegin:(NSString *)pageName;

/** Track page end
 
 @param pageName    page name
 */
- (void)trackPageEnd:(NSString *)pageName duration:(NSTimeInterval)duration;

/** Force start new tracking session
 
 */
- (void)startNewSession;

- (void)setPageName:(NSString *)pageName;

- (void)onBatchTimerFired:(NSTimer *)timer;

@end
