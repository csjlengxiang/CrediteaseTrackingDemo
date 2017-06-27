//
//  CTDispatcher.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTTrackingSession.h"
#import "CTTrackingEvent.h"

// 日志发送类
@interface CTDispatcher : NSObject

- (id)initWithAppId:(NSString *)appId;

- (void)setAppId:(NSString *)appId;

- (void)dispatchRealtimeEvent:(CTTrackingEvent *)event
                      session:(CTTrackingSession *)session
                      success:(void (^)(void))success
                      failure:(void (^)(void))failure;

- (void)dispatchBatchEvents:(NSArray *)events
                    session:(CTTrackingSession *)session
                    success:(void (^)(void))success
                    failure:(void (^)(void))failure;

@end
