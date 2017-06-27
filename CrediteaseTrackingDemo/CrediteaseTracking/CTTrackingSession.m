//
//  CTTrackingSession.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-28.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTTrackingSession.h"

@implementation CTTrackingSession

// 通过JSON数据设置跟踪事件的values值
- (void)setValueFromJson:(NSString *)json {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        //TODO: error handling
    } else {
        self.values = dic;
    }
}

// 获得JSON数据
- (NSString *)getJsonValue {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.values options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (error) {
        //TODO: error handling
        return nil;
    }
    return json;
}

@end
