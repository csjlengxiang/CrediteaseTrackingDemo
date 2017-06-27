//
//  CTTrackingHelper.m
//  CrediteaseTracking
//
//  Created by robin on 14-7-29.
//  Copyright (c) 2014年 CreditEase. All rights reserved.
//

#import "CTTrackingHelper.h"

@implementation CTTrackingHelper

// 将字典转换为JSON字符串
+ (NSString *)dicToJson:(NSDictionary *)dic {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (error) {
        //TODO: error handling
        return nil;
    }
    return json;
}

@end
