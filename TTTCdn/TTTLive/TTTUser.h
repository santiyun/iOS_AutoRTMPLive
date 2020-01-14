//
//  TTTUser.h
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTTUser : NSObject
@property (nonatomic, assign) int64_t uid;
@property (nonatomic, assign) BOOL mutedSelf; //是否静音
@property (nonatomic, assign) TTTRtcClientRole clientRole;
@property (nonatomic, readonly) BOOL isAnchor;

@property (nonatomic, assign) BOOL muteAudio;
@property (nonatomic, assign) BOOL muteVideo;
@property (nonatomic, assign) BOOL isUp;
@property (nonatomic, assign) BOOL isMe;


- (instancetype)initWith:(int64_t)uid;
@end
