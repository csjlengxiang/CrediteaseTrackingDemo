//
//  CTTrackingEvent.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import <Foundation/Foundation.h>

// 跟踪事件类
@interface CTTrackingEvent : NSObject

@property (nonatomic, strong) NSNumber *eid;            // 事件ID
@property (nonatomic, strong) NSNumber *timestamp;      // 时间戳
@property (nonatomic, strong) NSNumber *state;          // 状态
@property (nonatomic, strong) NSNumber *uploadRetry;    // 上传重试次数
@property (nonatomic, strong) NSNumber *sid;            // 对应会话ID
@property (nonatomic, copy)   NSString *type;             // 事件类型
@property (nonatomic, strong) NSDictionary *values;     // 需要传递的参数

- (void)setValueFromJson:(NSString *)json;

- (NSString *)getJsonValue;

@end
