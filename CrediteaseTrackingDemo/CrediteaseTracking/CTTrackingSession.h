//
//  CTTrackingSession.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import <Foundation/Foundation.h>

// 跟踪会话类
// 会话是一段时间内的事件集合
@interface CTTrackingSession : NSObject

@property (nonatomic, strong) NSNumber *sid;        // 会话ID
@property (nonatomic, strong) NSNumber *timestamp;  // 时间戳
@property (nonatomic, strong) NSNumber *lactAct;    // 最后行为时间
@property (nonatomic, strong) NSDictionary *values; // 需要传递的参数

- (void)setValueFromJson:(NSString *)json;

- (NSString *)getJsonValue;

@end
