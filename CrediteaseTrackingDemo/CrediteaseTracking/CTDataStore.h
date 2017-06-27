//
//  CTDataStore.h
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTTrackingEvent.h"
#import "CTTrackingSession.h"

// 事件状态
typedef NS_ENUM(NSInteger, CTEventState) {
    CTEventStateNew             = 1,    // 新的事件
    CTEventStateUploading       = 2,    // 正在上传
    CTEventStateUploaded        = 3,    // 已经上传
    CTEventStateUploadFailed    = 4     // 上传失败
};

// 数据源
// 操作数据库
@interface CTDataStore : NSObject

+ (CTDataStore *)sharedInstance;

- (CTTrackingSession *)getLastSession;

- (void)insertSession:(CTTrackingSession *)session;

- (CTTrackingSession *)getSessionById:(NSNumber *)sid;

- (void)updateSessionLastActivity:(CTTrackingSession *)session timestamp:(NSNumber *)timestamp;

- (void)insertEvent:(CTTrackingEvent *)event inSession:(CTTrackingSession *)session updateSession:(BOOL)update;

- (NSArray *)getEventsForUpload:(NSInteger)count;

- (void)deleteEvents:(NSArray *)events;

- (void)setState:(CTEventState)state forEvents:(NSArray *)events;

@end
