//
//  CTDataStore.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-24.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTDataStore.h"
#import "CTTrackingHelper.h"
#import "FMDB.h"

// 数据库文件名
static NSString * const DB_FILENAME = @"creditease-tracking-v1.sql";

/* -- SQL语句 -- */
static NSString * const SQL_CREATE_SESSION          = @"CREATE TABLE IF NOT EXISTS session(id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER, last_act INTEGER, 'values' TEXT)";
static NSString * const SQL_CREATE_EVENT            = @"CREATE TABLE IF NOT EXISTS event(id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER, state INTEGER, upload_retry INTEGER, session_id INTEGER, event_type TEXT, 'values' TEXT)";
static NSString * const SQL_INSERT_SESSION          = @"INSERT INTO session(timestamp, last_act, 'values') VALUES (?,?,?)";
static NSString * const SQL_INSERT_EVENT            = @"INSERT INTO event(timestamp, state, upload_retry, session_id, event_type, 'values') VALUES (?,?,?,?,?,?)";
static NSString * const SQL_DELETE_EVENT            = @"DELETE FROM event WHERE id=?";
static NSString * const SQL_UPDATE_SESSION_LAST_ACT = @"UPDATE session SET last_act=? WHERE id=?";
static NSString * const SQL_UPDATE_EVENT_STATE      = @"UPDATE event SET state=? WHERE id=?";
static NSString * const SQL_GET_LAST_SESSION        = @"SELECT * FROM session ORDER BY id DESC LIMIT 1";
static NSString * const SQL_GET_EVENT_FOR_UPLOAD    = @"SELECT * FROM event WHERE state=? ORDER BY id ASC LIMIT ?";
static NSString * const SQL_GET_SESSION_BY_ID       = @"SELECT * FROM session WHERE id=?";

@implementation CTDataStore {
    FMDatabase *_db;            // 数据库连接
    FMDatabaseQueue *_dbQueue;  // 数据库操作队列
}

// 返回单例
+ (instancetype)sharedInstance {
    static CTDataStore *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[CTDataStore alloc] init];
    });
    return instance;
}

// 初始化数据库和表格
- (id)init {
    self = [super init];
    if (self) {
        [self initDatabase];
        [self initTables];
    }
    return self;
}

// 初始化数据库
- (void)initDatabase {
    NSLog(@"initDatabase");
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *urls = [fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    if (urls.count == 0) {
        NSLog(@"Could not find library directory url");
        //TODO: error handling
    }
    NSURL *dbFile = [(NSURL *)urls[0] URLByAppendingPathComponent:DB_FILENAME];
    _db = [FMDatabase databaseWithPath:dbFile.path];
    if (![_db open]) {
        NSLog(@"Could not open database file:%@", dbFile);
        //TODO: error handling;
    }
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbFile.path];
}

// 初始化表格
- (void)initTables {
    NSLog(@"initTables");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:SQL_CREATE_SESSION];
        [db executeUpdate:SQL_CREATE_EVENT];
    }];
}

// 获得最近的会话
- (CTTrackingSession *)getLastSession {
    NSLog(@"getLastSession");
    __block CTTrackingSession *session;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [_db executeQuery:SQL_GET_LAST_SESSION];
        while ([rs next]) {
            session = [[CTTrackingSession alloc] init];
            session.sid = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:0]];
            session.timestamp = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:1]];
            session.lactAct = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:2]];
            [session setValueFromJson:[rs stringForColumnIndex:3]];
        }
    }];
    return session;
}

// 插入会话
- (void)insertSession:(CTTrackingSession *)session {
    NSLog(@"insertSession");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:SQL_INSERT_SESSION, session.timestamp, session.timestamp, [CTTrackingHelper dicToJson:session.values]];
        FMResultSet *rs = [_db executeQuery:SQL_GET_LAST_SESSION];
        while ([rs next]) {
            session.sid = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:0]];
            //session.timestamp = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:1]];
            //session.lactAct = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:2]];
            //[session setValueFromJson:[rs stringForColumnIndex:3]];
        }
    }];
}

// 通过会话ID获得会话
- (CTTrackingSession *)getSessionById:(NSNumber *)sid {
    NSLog(@"getSessionById");
    __block CTTrackingSession *session;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [_db executeQuery:SQL_GET_SESSION_BY_ID, sid];
        while ([rs next]) {
            session = [[CTTrackingSession alloc] init];
            session.sid = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:0]];
            session.timestamp = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:1]];
            session.lactAct = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:2]];
            [session setValueFromJson:[rs stringForColumnIndex:3]];
        }
    }];
    return session;
}

// 更新会话行为时间
- (void)updateSessionLastActivity:(CTTrackingSession *)session timestamp:(NSNumber *)timestamp {
    NSLog(@"updateSessionLastActivity");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:SQL_UPDATE_SESSION_LAST_ACT, timestamp, session.sid];
    }];
}

// 插入事件到会话中，update表示是否更细之前该会话的行为时间
- (void)insertEvent:(CTTrackingEvent *)event inSession:(CTTrackingSession *)session updateSession:(BOOL)update {
    NSLog(@"insertEvent");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (update)
            [db executeUpdate:SQL_UPDATE_SESSION_LAST_ACT, event.timestamp, session.sid];
        [db executeUpdate:SQL_INSERT_EVENT, event.timestamp, @(CTEventStateNew), @(0), session.sid, event.type, [CTTrackingHelper dicToJson:event.values]];
    }];
}

// 批量删除事件
- (void)deleteEvents:(NSArray *)events {
    NSLog(@"deleteEvents");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        for (CTTrackingEvent *ev in events) {
            [db executeUpdate:SQL_DELETE_EVENT, ev.eid];
        }
    }];
}

// 批量设置事件状态
- (void)setState:(CTEventState)state forEvents:(NSArray *)events {
    NSLog(@"setState");
    [_dbQueue inDatabase:^(FMDatabase *db) {
        for (CTTrackingEvent *ev in events) {
            [db executeUpdate:SQL_UPDATE_EVENT_STATE, @(state), ev.eid];
        }
    }];
}

// 获得需要上传的前count个事件
- (NSArray *)getEventsForUpload:(NSInteger)count {
    NSLog(@"getEventForUpload");
    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:count];
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:SQL_GET_EVENT_FOR_UPLOAD, @(CTEventStateNew), @(count)];
        while ([rs next]) {
            CTTrackingEvent *ev = [[CTTrackingEvent alloc] init];
            ev.eid = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:0]];
            ev.timestamp = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:1]];
            ev.state = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:2]];
            ev.uploadRetry = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:3]];
            ev.sid = [NSNumber numberWithLongLong:[rs longLongIntForColumnIndex:4]];
            ev.type = [rs stringForColumnIndex:5];
            [ev setValueFromJson:[rs stringForColumnIndex:6]];
            [events addObject:ev];
        }
        for (CTTrackingEvent *ev in events) {
            [db executeUpdate:SQL_UPDATE_EVENT_STATE, @(CTEventStateUploading), ev.eid];
        }
    }];
    return events;
}

@end
