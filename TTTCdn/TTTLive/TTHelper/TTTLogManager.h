//
//  TTTLogManager.h
//  TTTCdn
//
//  Created by 白泽 on 2019/12/23.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TTTReportType)
{
    TTTLiveReportPush,
    TTTLiveReportPuLL
};

NS_ASSUME_NONNULL_BEGIN

@interface TTTLogManager : NSObject

- (instancetype)initWithType:(TTTReportType)type withRoomId:(int64_t)roomID;

- (void)writeReporterLog:(NSString *)log;

@end

NS_ASSUME_NONNULL_END
