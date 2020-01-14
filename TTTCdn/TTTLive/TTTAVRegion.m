//
//  TTTAVRegion.m
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "TTTAVRegion.h"

@interface TTTAVRegion ()
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *videoView;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoStatsLabel;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;

@end

@implementation TTTAVRegion

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"TTTAVRegion" owner:self options:nil];
        _backgroundView.frame = self.bounds;
        _backgroundView.backgroundColor = [UIColor clearColor];
        [self addSubview:_backgroundView];
    }
    return self;
}



- (IBAction)switchCamera:(id)sender {
    [TTManager.rtcEngine switchCamera];
}

- (TTTVideoPosition *)videoPosition {
    if (!_videoPosition) {
        _videoPosition = [[TTTVideoPosition alloc] init];
        CGRect convertFrame = [self.superview convertRect:self.frame toView:self.superview.superview.superview];
        CGFloat width = UIScreen.mainScreen.bounds.size.width;
        CGFloat height = UIScreen.mainScreen.bounds.size.height;
        _videoPosition.x = self.frame.origin.x / width;
        _videoPosition.y = convertFrame.origin.y / height;
        _videoPosition.w = self.frame.size.width / width;
        _videoPosition.h = self.frame.size.height / height;
    }
    return _videoPosition;
}
#pragma mark - public
- (void)configureRegion:(TTTUser *)user {

    if (self.user) {
        [self closeRegionWithHidden:NO];
    }
    self.hidden = NO;
    self.user = user;
   
    _idLabel.hidden = NO;
    _audioStatsLabel.hidden = NO;
    _videoStatsLabel.hidden = NO;
    _videoView.hidden = NO;
    _idLabel.text = [NSString stringWithFormat:@"%lld", user.uid];
    _videoView.alpha = 1;
    
    TTTRtcVideoCanvas *videoCanvas = [[TTTRtcVideoCanvas alloc] init];
    videoCanvas.uid = user.uid;
    videoCanvas.renderMode = TTTRtc_Render_Adaptive;
    videoCanvas.view = _videoView;
    if (TTManager.me == user) {
        [TTManager.rtcEngine setupLocalVideo:videoCanvas];
        _switchBtn.hidden = NO;
    } else {
        [TTManager.rtcEngine setupRemoteVideo:videoCanvas];
    }
   
}

- (void)closeRegionWithHidden:(BOOL)hidden
{
    
     self.hidden = hidden;
    _idLabel.hidden = YES;
    _switchBtn.hidden = YES;
    _audioStatsLabel.hidden = YES;
    _videoStatsLabel.hidden = YES;
    _videoView.image = [UIImage imageNamed:@"video_head"];
    _videoView.alpha = 0.65;
    _user = nil;
}


- (void)setLocalAudioStats:(NSUInteger)stats {
    _audioStatsLabel.text = [NSString stringWithFormat:@"A-↑%lukbps",(unsigned long)stats];
}

- (void)setLocalVideoStats:(NSUInteger)stats {
    _videoStatsLabel.text = [NSString stringWithFormat:@"V-↑%lukbps",(unsigned long)stats];
}

- (void)setRemoterAudioStats:(NSUInteger)stats {
    _audioStatsLabel.text = [NSString stringWithFormat:@"A-↓%lukbps",(unsigned long)stats];
}

- (void)setRemoterVideoStats:(NSUInteger)stats {
    _videoStatsLabel.text = [NSString stringWithFormat:@"V-↓%lukbps",(unsigned long)stats];
}

@end
