//
//  TTTRtcManager.h
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TTTLiveEngineKit/TTTLiveEngineKit.h>
#import "TTTUser.h"

@interface TTTRtcManager : NSObject
@property (nonatomic, strong) TTTLiveEngineKit *rtcEngine;
@property (nonatomic, strong) TTTUser *me;
@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, assign) int64_t uid;

+ (instancetype)manager;
@end
