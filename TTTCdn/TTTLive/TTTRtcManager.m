//
//  TTTRtcManager.m
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "TTTRtcManager.h"

@implementation TTTRtcManager
static id _manager;
+ (instancetype)manager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [super allocWithZone:zone];
    });
    return _manager;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _manager;
}   

- (instancetype)init
{
    self = [super init];
    if (self) {
        //填写申请的appId
        _rtcEngine = [TTTLiveEngineKit sharedEngineWithAppId:<#name#> delegate:nil];

        _me = [[TTTUser alloc] initWith:0];
      
    }
    return self;
}

@end
