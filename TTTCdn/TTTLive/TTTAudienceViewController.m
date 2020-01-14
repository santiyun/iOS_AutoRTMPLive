//
//  TTTAudienceViewController.m
//  TTTLive
//
//  Created by Work on 2019/6/5.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "TTTAudienceViewController.h"
#import "TTTAVRegion.h"
#import "TTTLogManager.h"

@interface TTTAudienceViewController ()<TTTLiveEngineDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *anchorVideoView;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *anchorIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *auiostatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoStatsLabel;

@property (weak, nonatomic) IBOutlet UIButton *micBtn;

@property (nonatomic, copy) NSString * pullURL;
@property (weak, nonatomic) IBOutlet UIView *avRegionsView;

@property (nonatomic, strong) NSMutableArray <TTTUser *>* users;
@property (nonatomic, strong) NSMutableArray <TTTAVRegion *>* avRegions;

@property (nonatomic, strong) TTTLogManager * logManager;

//主播uid
@property (nonatomic) int64_t anchorUid;
//停止次数（在流没有断掉的时候有时候会出现流停掉）
@property (nonatomic) int stopTime;

@end

@implementation TTTAudienceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _logManager = [[TTTLogManager alloc] initWithType:TTTLiveReportPuLL withRoomId:TTManager.roomID.intValue];
    _anchorVideoView.backgroundColor = [UIColor clearColor];
    _roomIDLabel.text = [NSString stringWithFormat:@"房号: %@", TTManager.roomID];
    _anchorIdLabel.text = [NSString stringWithFormat:@"用户ID:%lld",TTManager.uid];
    _auiostatsLabel.text = nil;
    _videoStatsLabel.text = nil;
    _users = [NSMutableArray array];
    _avRegions = [NSMutableArray array];
    for (UIView * subView in _avRegionsView.subviews) {
        if ([subView isKindOfClass:[TTTAVRegion class]]) {
            [_avRegions addObject:(TTTAVRegion*)subView];
        }
    }
   
    _pullURL = [@"rtmp://pullbsy.3ttech.cn/sdk/" stringByAppendingString:TTManager.roomID];
   //_pullURL = [@"rtmp://pullqny.3ttech.cn/sdk/" stringByAppendingString:TTManager.roomID];
   
    [self startPullRtmp];
    [TTProgressHud showHud:self.view];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [TTManager.rtcEngine leaveChannel:nil];
}

- (void)startPullRtmp {
    _auiostatsLabel.text = nil;
    _videoStatsLabel.text = nil;
    _avRegionsView.hidden = YES;
  
    [TTManager.rtcEngine livePlayerWithDefaultOptionsWithURL:[NSURL URLWithString:_pullURL] withFrame:UIScreen.mainScreen.bounds withPlayerView:_anchorVideoView];
    [TTManager.rtcEngine setDelegate:self];
    [TTManager.rtcEngine livePlayerPlay];
}


//做上麦拉流和cdn拉流切换...注意不要短时间重复操作
- (IBAction)openMicAction:(UIButton *)sender {
    if (sender.isSelected) {//退出房间
        [TTManager.rtcEngine downChannelWithRtmpURL:_pullURL];
       
    } else { //观众上麦__加入房间
        BOOL swapWH = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation);
        [TTProgressHud showHud:self.view message:@"连麦中"];
        //设置频道模式：直播
        [TTManager.rtcEngine setChannelProfile:TTTRtc_ChannelProfile_LiveBroadcasting];
        // 设置日志文件
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = directories.firstObject;
      
        NSString *logFileName = [NSString stringWithFormat:@"/autoLive_%@_%.2f.log",TTManager.roomID,[[NSDate date] timeIntervalSince1970]];
        logFileName = [documentsDirectory stringByAppendingString:logFileName];
        [TTManager.rtcEngine setLogFile:logFileName];
        [TTManager.rtcEngine setLogFilter:TTTRtc_LogFilter_Debug];
        //设置角色为副播
        [TTManager.rtcEngine setClientRole:TTTRtc_ClientRole_Broadcaster];
        //设置上传分辨率为360P, 竖屏模式下交换宽高
        [TTManager.rtcEngine setVideoProfile:TTTRtc_VideoProfile_360P swapWidthAndHeight:swapWH];
        [TTManager.rtcEngine setPreferAudioCodec:TTTRtc_AudioCodec_AAC bitrate:64 channels:1];
        //加入房间
        int result =  [TTManager.rtcEngine upChannelByKey:nil channelName:TTManager.roomID uid:TTManager.uid joinSuccess:nil];
        if (result == -1) {
            [TTProgressHud hideHud:self.view];
        }
    }
}

- (IBAction)exit:(id)sender {
    __weak TTTAudienceViewController *weakSelf = self;
    UIAlertController *alert  = [UIAlertController alertControllerWithTitle:@"提示" message:@"您确定要退出房间吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TTManager.rtcEngine leaveChannel:nil];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:sureAction];
    [self presentViewController:alert animated:YES completion:nil];
}

//拉流状态发生改变
- (void)rtcEngine:(TTTLiveEngineKit *)engine livePlayerStatusDidChange:(TTTLivePlayerStatus)playerStatus {
    if (playerStatus == TTTLivePlayerStatusPlaying) {//开始播放cdn音视频流
        _stopTime = 0;
        [TTProgressHud hideHud:self.view];
    }
    if (playerStatus == TTTLivePlayerStatusError || playerStatus == TTTLivePlayerStatusStopped) {
        [TTProgressHud hideHud:self.view];
        [TTManager.rtcEngine livePlayerStop];

        [self.view.window showToast:@"拉流失败"];
        [TTManager.rtcEngine leaveChannel:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
//拉流出现error
- (void)rtcEngine:(TTTLiveEngineKit *)engine livePlayerStoppedWithError:(NSError *)error{

    [TTProgressHud hideHud:self.view];
    [TTManager.rtcEngine livePlayerStop];

    [self.view.window showToast:@"拉流失败"];
    [TTManager.rtcEngine leaveChannel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];

    
}
//拉流音视频码率获取
- (void)rtcEngine:(TTTLiveEngineKit *)engine livePlayerStatsInfo:(TTTLivePlayerStatsInfo *)statsInfo {

    _auiostatsLabel.text = [NSString stringWithFormat:@"A-↓%dkbps",statsInfo.audioBitrate];
    _videoStatsLabel.text = [NSString stringWithFormat:@"V-↓%dkbps",statsInfo.videoBitrate];
    
}

#pragma mark - TTTRtcEngineDelegate
//加入房间成功
-(void)rtcEngine:(TTTLiveEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(int64_t)uid elapsed:(NSInteger)elapsed {
    [_users addObject:TTManager.me];
    [TTProgressHud hideHud:self.view];
}

- (void)rtcEngine:(TTTLiveEngineKit *)engine didSwitchChannelAction:(TTTLiveActionStatus)status
{
    if (status == TTTLiveActionDownChannelSuccess) {
        [TTManager.rtcEngine stopPreview];
        _auiostatsLabel.text = nil;
        _videoStatsLabel.text = nil;
        _avRegionsView.hidden = YES;
        [self clearAll];
        _micBtn.selected = NO;
    }
    else if (status == TTTLiveActionUpChannelSuccess)
    {
        _avRegionsView.hidden = NO;
          _micBtn.selected = YES;
          [TTManager.rtcEngine startPreview];
    }
}


//有用户加入房间
- (void)rtcEngine:(TTTLiveEngineKit *)engine didJoinedOfUid:(int64_t)uid clientRole:(TTTRtcClientRole)clientRole isVideoEnabled:(BOOL)isVideoEnabled elapsed:(NSInteger)elapsed {
    TTTUser *user = [[TTTUser alloc] initWith:uid];
    user.clientRole = clientRole;
    [_users addObject:user];
    if (clientRole == TTTRtc_ClientRole_Anchor) _anchorUid = uid;
}

- (void)rtcEngine:(TTTLiveEngineKit *)engine didKickedOutOfUid:(int64_t)uid reason:(TTTRtcKickedOutReason)reason
{
    [TTProgressHud hideHud:self.view];
    [_users removeObject:TTManager.me];
    [self openMicAction:_micBtn];
}

//房间内用户离线...
- (void)rtcEngine:(TTTLiveEngineKit *)engine didOfflineOfUid:(int64_t)uid reason:(TTTRtcUserOfflineReason)reason {

    TTTUser *user = [self getUser:uid];
    if (!user) { return; }
    [[self getAVRegion:uid] closeRegionWithHidden:YES];
    [_users removeObject:user];
}

//SEI的回调
- (void)rtcEngine:(TTTLiveEngineKit *)engine onSetSEI:(NSString *)SEI
{
       NSData *seiData = [SEI dataUsingEncoding:NSUTF8StringEncoding];
       NSDictionary *json = [NSJSONSerialization JSONObjectWithData:seiData options:NSJSONReadingMutableLeaves error:nil];
       NSArray<NSDictionary *> *posArray = json[@"pos"];
       for (NSDictionary *obj in posArray) {
           int64_t uid = [obj[@"id"] longLongValue];
           TTTUser *user = [self getUser:uid];
           if (user.clientRole == TTTRtc_ClientRole_Broadcaster) {
               if (![self getAVRegion:uid]) {
                   TTTVideoPosition *videoPosition = [[TTTVideoPosition alloc] init];
                   videoPosition.x = [obj[@"x"] doubleValue];
                   videoPosition.y = [obj[@"y"] doubleValue];
                   videoPosition.w = [obj[@"w"] doubleValue];
                   videoPosition.h = [obj[@"h"] doubleValue];
                   TTTAVRegion * AVRegion = [self positionAVRegion:videoPosition];
                   if (!AVRegion.user) {
                       [AVRegion configureRegion:user];
                   }
                   else
                   {
                       [[self getAvaiableAVRegion] configureRegion:user];
                   }
               }
           }
       }
}



//远端用户解码第一帧--显示主播的视频
-(void)rtcEngine:(TTTLiveEngineKit *)engine firstRemoteVideoFrameDecodedOfUid:(int64_t)uid deviceId:(NSString *)devId size:(CGSize)size elapsed:(NSInteger)elapsed {
    if (uid != _anchorUid) { return; }
    _anchorIdLabel.text = [@"主播id: " stringByAppendingFormat:@"%lld", uid];
}

//显示本人音视频上行码率
- (void)rtcEngine:(TTTLiveEngineKit *)engine reportRtcStats:(TTTRtcStats *)stats {
    [[self getAVRegion:TTManager.me.uid] setLocalAudioStats:stats.txAudioKBitrate];
    [[self getAVRegion:TTManager.me.uid] setLocalVideoStats:stats.txVideoKBitrate];
}

//显示主播下行音频码率
- (void)rtcEngine:(TTTLiveEngineKit *)engine remoteAudioStats:(TTTRtcRemoteAudioStats *)stats {
       TTTUser *user = [self getUser:stats.uid];
       if (!user) { return; }
       if (user.isAnchor) {
            _auiostatsLabel.text = [NSString stringWithFormat:@"A-↓%lukbps", (unsigned long)stats.receivedBitrate];
       } else {
           [[self getAVRegion:stats.uid] setRemoterAudioStats:stats.receivedBitrate];
       }
   
}

//显示显示主播下行视频码率
- (void)rtcEngine:(TTTLiveEngineKit *)engine remoteVideoStats:(TTTRtcRemoteVideoStats *)stats {
    TTTUser *user = [self getUser:stats.uid];
       if (!user) { return; }
       if (user.isAnchor) {
           _videoStatsLabel.text = [NSString stringWithFormat:@"V-↓%lukbps", (unsigned long)stats.receivedBitrate];
       } else {
           [[self getAVRegion:stats.uid] setRemoterVideoStats:stats.receivedBitrate];
       }
   
}

//加入房间失败
-(void)rtcEngine:(TTTLiveEngineKit *)engine didOccurError:(TTTRtcErrorCode)errorCode {
    NSString *errorInfo = @"";
    switch (errorCode) {
        case TTTRtc_Error_Enter_TimeOut:
            errorInfo = @"超时,10秒未收到服务器返回结果";
            break;
        case TTTRtc_Error_Enter_Failed:
            errorInfo = @"该直播间不存在";
            break;
        case TTTRtc_Error_Enter_BadVersion:
            errorInfo = @"版本错误";
            break;
        case TTTRtc_Error_InvalidChannelName:
            errorInfo = @"Invalid channel name";
            break;
        case TTTRtc_Error_Enter_NoAnchor:
            errorInfo = @"房间内无主播";
            break;
        default:
            errorInfo = [NSString stringWithFormat:@"未知错误：%zd",errorCode];
            break;
    }
   // [self startPullRtmp];
    _micBtn.selected = NO;
    [TTProgressHud hideHud:self.view];
    [self showToast:errorInfo];
}

//和服务器连接断开(会自动重连参考下面两个回调)...可以根据自己监测网络实际结果为准判断断网
- (void)rtcEngineConnectionDidLost:(TTTLiveEngineKit *)engine {
    [TTProgressHud showHud:self.view message:@"网络链接丢失，正在重连..."];
}

//网络重连失败
- (void)rtcEngineReconnectServerTimeout:(TTTLiveEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
    [self.view.window showToast:@"网络丢失，请检查网络"];
    [engine leaveChannel:nil];
    [engine stopPreview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//网络重连成功
- (void)rtcEngineReconnectServerSucceed:(TTTLiveEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
}



- (void)rtcEngineLiveReporterLog:(NSString *)logStr
{
    [_logManager writeReporterLog:logStr];
}


#pragma mark - helper mehtod
- (TTTAVRegion *)getAvaiableAVRegion {
    __block TTTAVRegion *region = nil;
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.user) {
            region = obj;
            *stop = YES;
        }
    }];
    return region;
}

- (TTTAVRegion *)getAVRegion:(int64_t)uid {
    __block TTTAVRegion *region = nil;
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.user.uid == uid) {
            region = obj;
            *stop = YES;
        }
    }];
    return region;
}

- (TTTUser *)getUser:(int64_t)uid {
    __block TTTUser *user = nil;
    [_users enumerateObjectsUsingBlock:^(TTTUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.uid == uid) {
            user = obj;
            *stop = YES;
        }
    }];
    return user;
}

- (TTTAVRegion *)positionAVRegion:(TTTVideoPosition *)position {
    __block TTTAVRegion *region = nil;
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (position.column == obj.videoPosition.column && position.row == obj.videoPosition.row) {
            region = obj;
            *stop = YES;
        }
    }];
    return region;
}

- (void)clearAll
{
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj closeRegionWithHidden:YES];
    }];
    [_users removeAllObjects];
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}
@end
