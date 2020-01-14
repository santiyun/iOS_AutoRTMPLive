//
//  TTTLiveViewController.m
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "TTTLiveViewController.h"
#import "TTTAVRegion.h"
#import "TTTUser.h"
#import "TTTLogManager.h"

//#define PUSHRTMPURL @"rtmp://pushbsy.3ttech.cn/sdk"
//#define PUSHRTMPURL @"rtmp://pushqny.3ttech.cn/sdk"

@interface TTTLiveViewController ()<TTTLiveEngineDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *anchorVideoView;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *anchorIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoStatsLabel;

@property (weak, nonatomic) IBOutlet UIButton *micBtn;
@property (nonatomic) int pushIndex;//推流的下标
//主播设置SEI
@property (nonatomic, strong) TTTRtcVideoCompositingLayout *videoLayout;

@property (nonatomic, strong) NSMutableArray<TTTAVRegion *>* avRegions;
@property (nonatomic, strong) NSMutableArray<TTTUser *> *users;

@property (weak, nonatomic) IBOutlet UIView *AvRegionsView;

@property (nonatomic, copy) NSString * pushRtmpUrl;
@property (nonatomic, strong) TTTLogManager * logManager;


@end

@implementation TTTLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _logManager = [[TTTLogManager alloc] initWithType:TTTLiveReportPush withRoomId:TTManager.roomID.intValue];
    _pushIndex = 10;
    _roomIDLabel.text = [NSString stringWithFormat:@"房号: %@", TTManager.roomID];
    _anchorIdLabel.text = [NSString stringWithFormat:@"id: %lld", TTManager.uid];
    TTManager.rtcEngine.delegate = self;
    _avRegions = [NSMutableArray array];
    _users = [NSMutableArray array];
    _AvRegionsView.hidden = YES;
    [_users addObject:TTManager.me];
    //开启预览--设置本地渲染
    [TTManager.rtcEngine setVideoProfile:TTTRtc_VideoProfile_360P swapWidthAndHeight:YES];
    [TTManager.rtcEngine startPreview];
    TTTRtcVideoCanvas * videoCanvas = [[TTTRtcVideoCanvas alloc] init];
    videoCanvas.view = _anchorVideoView;
    videoCanvas.renderMode = TTTRtc_Render_Adaptive;
    [TTManager.rtcEngine setupLocalVideo:videoCanvas];
   
    for (UIView * subView in _AvRegionsView.subviews) {
        if ([subView isKindOfClass:[TTTAVRegion class]]) {
            [_avRegions addObject:(TTTAVRegion *)subView];
        }
    }
    
    _pushRtmpUrl = @"rtmp://pushbsy.3ttech.cn/sdk"; //lev
   // _pushRtmpUrl = @"rtmp://pushqny.3ttech.cn/sdk"; //serialnum
  
    [self startPushRtmp];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}


- (void)startPushRtmp {
    //(杀死程序等)异常推流失败...不要用小的尾号推流会出现重复成功失败

    NSString * rtmpUrl = [NSString stringWithFormat:@"%@/%@?lev=%d",_pushRtmpUrl,TTManager.roomID,_pushIndex++];
    NSLog(@"rtmpUrl === %@",rtmpUrl);
    //开始直推rtmp流
    [TTManager.rtcEngine startRtmpPublish:rtmpUrl];
}

//做上麦推流和直推流切换...注意不要短时间重复上下麦
- (IBAction)openMic:(UIButton *)sender {
    if (sender.isSelected) {//退出房间
       
        NSString * rtmpUrl = [NSString stringWithFormat:@"%@/%@?lev=%d",_pushRtmpUrl,TTManager.roomID,_pushIndex++];
        [TTManager.rtcEngine downChannelWithRtmpURL:rtmpUrl];
    } else { //加入房间
        [self clearAll];
        BOOL swapWH = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation);
        [TTProgressHud showHud:self.view message:@"上麦中"];
        //设置代理
        TTManager.rtcEngine.delegate = self;
        NSString * serverIp = [[NSUserDefaults standardUserDefaults] stringForKey:@"SERVERIP"];
        int port = [[NSUserDefaults standardUserDefaults] stringForKey:@"PORT"].intValue;
        [TTManager.rtcEngine setServerIp:serverIp    port:port];
        
        //设置频道模式：直播
        [TTManager.rtcEngine setChannelProfile:TTTRtc_ChannelProfile_LiveBroadcasting];
        // 设置日志文件
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = directories.firstObject; 
      
        NSString *logFileName = [NSString stringWithFormat:@"/autoLive_%@_%.2f.log",TTManager.roomID,[[NSDate date] timeIntervalSince1970]];
        logFileName = [documentsDirectory stringByAppendingString:logFileName];
        [TTManager.rtcEngine setLogFile:logFileName];
        [TTManager.rtcEngine setLogFilter:TTTRtc_LogFilter_Debug];
        //设置角色为主播
        [TTManager.rtcEngine setClientRole:TTTRtc_ClientRole_Anchor];
        //设置上传分辨率为360P, 竖屏模式下交换宽高
        [TTManager.rtcEngine setVideoProfile:TTTRtc_VideoProfile_360P swapWidthAndHeight:swapWH];
        //设置编码格式为aac
        [TTManager.rtcEngine setPreferAudioCodec:TTTRtc_AudioCodec_AAC bitrate:64 channels:1];
        //设置推流地址
        TTTPublisherConfigurationBuilder *builder = [[TTTPublisherConfigurationBuilder alloc] init];
        NSString * pushURL = [NSString stringWithFormat:@"%@/%@?lev=%d",_pushRtmpUrl,TTManager.roomID,_pushIndex++];
        [builder setPublisherUrl:pushURL];
        [TTManager.rtcEngine configPublisher:builder.build];
        //加入房间
        [TTManager.rtcEngine upChannelByKey:nil channelName:TTManager.roomID uid:TTManager.uid joinSuccess:nil];
    }
}

//切换摄像头
- (IBAction)leftBtnsAction:(UIButton *)sender {
    [TTManager.rtcEngine switchCamera];
}

//离开当前房间
- (IBAction)exitChannel:(id)sender {
    __weak TTTLiveViewController *weakSelf = self;
    UIAlertController *alert  = [UIAlertController alertControllerWithTitle:@"提示" message:@"您确定要退出房间吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        [TTManager.rtcEngine stopPreview];
        [TTManager.rtcEngine leaveChannel:nil];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }]; 
    [alert addAction:sureAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TTTRtcEngineDelegate
- (void)rtcEngine:(TTTLiveEngineKit *)engine onStatusOfRtmpPublish:(TTTRtcRtmpPublishStatus)status {
    if (status == TTTRtc_RtmpPublishStatus_LinkSuccessed) {
        [self showToast:@"推流成功"];
    } else if (status == TTTRtc_RtmpPublishStatus_LinkFailed) {
        [self.view.window showToast:@"推流失败"];
        [engine leaveChannel:nil];
        [engine stopPreview];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (status == TTTRtc_RtmpPublishStatus_InitError) {
        [self showToast:@"初始化RTMP发送器失败"];
    } else if (status == TTTRtc_RtmpPublishStatus_OpenError) {
        [self showToast:@"打开RTMP链接失败"];
    } else if (status == TTTRtc_RtmpPublishStatus_AudioNoBuf) {

    } else if (status == TTTRtc_RtmpPublishStatus_VideoNoBuf) {

    }
}

//非直推---推流rtmp状态
- (void)rtcEngine:(TTTLiveEngineKit *)engine reportRtmpStatus:(BOOL)status rtmpUrl:(NSString *)rtmpUrl {
    if (status) {

    } else {
        //在房间内出现推流rtmp失败...更新rtmp地址(更新一个新的可以推流的地址)
        NSString * pushURL = [NSString stringWithFormat:@"%@/%@?lev=%d",_pushRtmpUrl,TTManager.roomID,_pushIndex++];
        [engine updateRtmpUrl:pushURL];
    }
}

- (void)rtcEngine:(TTTLiveEngineKit *)engine didSwitchChannelAction:(TTTLiveActionStatus)status
{
    if (status == TTTLiveActionDownChannelSuccess) {
        _micBtn.selected = NO;
        _AvRegionsView.hidden = YES;
        [self clearAll];
    }
    else if (status == TTTLiveActionDownChannelFailed)
    {
        [self.view.window showToast:@"下麦失败"];
    }
    else if (status == TTTLiveActionUpChannelSuccess)
    {
        _micBtn.selected = YES;
    }
}


//加入房间成功
- (void)rtcEngine:(TTTLiveEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(int64_t)uid elapsed:(NSInteger)elapsed
{
    _AvRegionsView.hidden = NO;
    [TTProgressHud hideHud:self.view];
}



//有用户加入房间
- (void)rtcEngine:(TTTLiveEngineKit *)engine didJoinedOfUid:(int64_t)uid clientRole:(TTTRtcClientRole)clientRole isVideoEnabled:(BOOL)isVideoEnabled elapsed:(NSInteger)elapsed {
    if (clientRole != TTTRtc_ClientRole_Broadcaster) {
        return;
    }
    TTTUser *user = [[TTTUser alloc] initWith:uid];
     user.clientRole = clientRole;
     [_users addObject:user];
     [[self getAvaiableAVRegion] configureRegion:user];
     [self refreshVideoCompositingLayout];
   
    
}

//房间内用户离线...作为主播端也主动掉线切喊为直推rtmp
- (void)rtcEngine:(TTTLiveEngineKit *)engine didOfflineOfUid:(int64_t)uid reason:(TTTRtcUserOfflineReason)reason
{

    [[self getAVRegion:uid] closeRegionWithHidden:NO];
    TTTUser *user = [self getUser:uid];
    if (!user) { return; }
    [_users removeObject:user];
   
}


- (void)rtcEngine:(TTTLiveEngineKit *)engine localAudioStats:(TTTRtcLocalAudioStats *)stats
{
    _audioStatsLabel.text = [NSString stringWithFormat:@"A-↑%lukbps", (unsigned long)stats.sentBitrate];
  //  NSLog(@"local_AudioStats = A-↑%lukbps",(unsigned long)stats.sentBitrate);
}

- (void)rtcEngine:(TTTLiveEngineKit *)engine localVideoStats:(TTTRtcLocalVideoStats *)stats
{
    _videoStatsLabel.text = [NSString stringWithFormat:@"V-↑%lukbps", (unsigned long)stats.sentBitrate];
  //  NSLog(@"local_VideoStats = V-↑%lukbps",(unsigned long)stats.sentBitrate);
}


//统计收到远端用户音频下行码率
- (void)rtcEngine:(TTTLiveEngineKit *)engine remoteAudioStats:(TTTRtcRemoteAudioStats *)stats {

    TTTUser *user = [self getUser:stats.uid];
    if (!user) { return; }
    [[self getAVRegion:stats.uid] setRemoterAudioStats:stats.receivedBitrate];
}

//统计收到远端用户视频下行码率
- (void)rtcEngine:(TTTLiveEngineKit *)engine remoteVideoStats:(TTTRtcRemoteVideoStats *)stats {
    TTTUser *user = [self getUser:stats.uid];
    if (!user) { return; }
    [[self getAVRegion:stats.uid] setRemoterVideoStats:stats.receivedBitrate];
}

//和服务器连接断开(会自动重连参考下面两个回调)...可以根据自己监测网络实际结果为准判断断网
- (void)rtcEngineConnectionDidLost:(TTTLiveEngineKit *)engine {
    [TTProgressHud showHud:self.view message:@"网络链接丢失，正在重连..."];
}

//网络重连成功
- (void)rtcEngineReconnectServerSucceed:(TTTLiveEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
}

//网络重连失败
- (void)rtcEngineReconnectServerTimeout:(TTTLiveEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
    [self.view.window showToast:@"网络丢失，请检查网络"];
    [engine leaveChannel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//被踢出房间
- (void)rtcEngine:(TTTLiveEngineKit *)engine didKickedOutOfUid:(int64_t)uid reason:(TTTRtcKickedOutReason)reason {
    NSString *errorInfo = @"";
    switch (reason) {
        case TTTRtc_KickedOut_ReLogin:
            errorInfo = @"重复登录";
            break;
        case TTTRtc_KickedOut_PushRtmpFailed:
            errorInfo = @"rtmp推流失败";
            break;
        case TTTRtc_KickedOut_NewChairEnter:
            errorInfo = @"其他人以主播身份进入";
            break;
        default:
            errorInfo = @"未知错误";
            break;
    }
    [self.view.window showToast:errorInfo];
    [engine leaveChannel:nil];
    [engine stopPreview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//---------加入房间失败
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
    [TTProgressHud hideHud:self.view];
    [self showToast:errorInfo];
    NSString * rtmpUrl = [NSString stringWithFormat:@"%@/%@?lev=%d",_pushRtmpUrl,TTManager.roomID,_pushIndex++];
    [TTManager.rtcEngine downChannelWithRtmpURL:rtmpUrl];
    _micBtn.selected = NO;
}


- (TTTRtcVideoCompositingLayout *)videoLayout {
    if (!_videoLayout) {
        _videoLayout = [[TTTRtcVideoCompositingLayout alloc] init];
        _videoLayout.backgroundColor = @"#e8e6e8";
        _videoLayout.canvasWidth = 360;
        _videoLayout.canvasHeight = 640;
    }
    return _videoLayout;
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

- (void)refreshVideoCompositingLayout {
    TTTRtcVideoCompositingLayout *videoLayout = self.videoLayout;
    if (!videoLayout) { return; }
    [videoLayout.regions removeAllObjects];
    TTTRtcVideoCompositingRegion *anchorRegion = [[TTTRtcVideoCompositingRegion alloc] init];
    anchorRegion.uid = TTManager.me.uid;
    anchorRegion.x = 0;
    anchorRegion.y = 0;
    anchorRegion.width = 1;
    anchorRegion.height = 1;
    anchorRegion.zOrder = 0;
    anchorRegion.alpha = 1;
    anchorRegion.renderMode = TTTRtc_Render_Adaptive;
    [videoLayout.regions addObject:anchorRegion];
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.user) {
            TTTRtcVideoCompositingRegion *videoRegion = [[TTTRtcVideoCompositingRegion alloc] init];
            videoRegion.uid = obj.user.uid;
            videoRegion.x = obj.videoPosition.x;
            videoRegion.y = obj.videoPosition.y;
            videoRegion.width = obj.videoPosition.w;
            videoRegion.height = obj.videoPosition.h;
            videoRegion.zOrder = 1;
            videoRegion.alpha = 1;
            videoRegion.renderMode = TTTRtc_Render_Adaptive;
            [videoLayout.regions addObject:videoRegion];
        }
    }];
    [TTManager.rtcEngine setVideoCompositingLayout:videoLayout];
}

- (void)clearAll
{
    [_avRegions enumerateObjectsUsingBlock:^(TTTAVRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj closeRegionWithHidden:NO];
    }];
    [_users removeAllObjects];
}


- (void)dealloc
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    NSLog(@"%s",__func__);
}
@end
