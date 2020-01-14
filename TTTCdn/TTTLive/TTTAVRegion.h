//
//  TTTAVRegion.h
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTVideoPosition.h"
#import "TTTUser.h"

@interface TTTAVRegion : UIView

@property (nonatomic, strong) TTTUser *user;
@property (nonatomic, strong) TTTVideoPosition *videoPosition;

- (void)configureRegion:(TTTUser *)user;
- (void)closeRegionWithHidden:(BOOL)hidden;
- (void)setLocalAudioStats:(NSUInteger)stats;
- (void)setLocalVideoStats:(NSUInteger)stats;
- (void)setRemoterAudioStats:(NSUInteger)stats;
- (void)setRemoterVideoStats:(NSUInteger)stats;
@end
