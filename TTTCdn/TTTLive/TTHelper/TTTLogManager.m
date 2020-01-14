//
//  TTTLogManager.m
//  TTTCdn
//
//  Created by 白泽 on 2019/12/23.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "TTTLogManager.h"
#import <sys/time.h>

@interface TTTLogManager ()

@property (nonatomic, strong) NSFileHandle *logHandle;
@property (nonatomic, strong) NSDateFormatter * formatter;

@end

@implementation TTTLogManager


- (instancetype)initWithType:(TTTReportType)type withRoomId:(int64_t)roomID
{
    self = [super init];
    if (self) {
    
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        _formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self getTimestamp] / 1000.0];
        NSString * time = [_formatter stringFromDate:date];
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString * logDir = [document stringByAppendingFormat:@"/Log%@_%lld_%@.log",type ? @"pull" : @"push",roomID,time];

       [NSFileManager.defaultManager createFileAtPath:logDir contents:nil attributes:nil];
        _logHandle = [NSFileHandle fileHandleForWritingAtPath:logDir];
    }
    return self;
}


- (void)writeReporterLog:(NSString *)log
{
    if (_logHandle && log.length > 0) {
        long time = [NSDate.date timeIntervalSince1970];
        NSString *writeStr = [log stringByAppendingFormat:@"__%lld___%ld\n",TTManager.uid,time];
        @try {
            [_logHandle writeData:[writeStr dataUsingEncoding:NSUTF8StringEncoding]];
        } @catch (NSException *exception) {
            NSLog(@"Func log failed to write data: %@", exception.reason);
        }
    }
}

- (void)dealloc
{
    if (_logHandle) {
           [_logHandle closeFile];
           _logHandle = nil;
       }
}

- (long)getTimestamp {
    struct timeval ts;
    gettimeofday(&ts, NULL);
    unsigned long us = ts.tv_sec * 1000;
    return us + ts.tv_usec / 1000; // millisecond
}



@end
