//
//  TTTLoginViewController.m
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "TTTLoginViewController.h"

@interface TTTLoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *anchorBtn;
@property (weak, nonatomic) IBOutlet UITextField *roomIDTF;
@property (weak, nonatomic) IBOutlet UILabel *websiteLabel;


@property (nonatomic, weak) UIButton *roleSelectedBtn;
@property (nonatomic, assign) int64_t uid;
@property (nonatomic, assign) NSInteger selectedCDN;
@end

@implementation TTTLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _roleSelectedBtn = _anchorBtn;
    NSString *dateStr = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    _websiteLabel.text = [TTTLiveEngineKit.getSdkVersion stringByAppendingFormat:@"__%@", dateStr];
    _uid = arc4random() % 100000 + 1;
    int64_t roomID = [[NSUserDefaults standardUserDefaults] stringForKey:@"ENTERROOMID"].integerValue;
    roomID = arc4random() % 1000000 + 1;
    _roomIDTF.text = [NSString stringWithFormat:@"%lld", roomID];
    
}

- (IBAction)roleBtnsAction:(UIButton *)sender {
    if (sender.isSelected) { return; }
    _roleSelectedBtn.selected = NO;
    _roleSelectedBtn.backgroundColor = [UIColor colorWithRed:139 / 255.0 green:39 / 255.0 blue:54 / 255.0 alpha:1];
    sender.selected = YES;
    sender.backgroundColor = [UIColor colorWithRed:1 green:245 / 255.0 blue:11 / 255.0 alpha:1];
    _roleSelectedBtn = sender;
}

- (IBAction)enterChannel:(id)sender {
    if (_roomIDTF.text.length == 0 || _roomIDTF.text.length >= 19) {
        [self showToast:@"请输入19位以内的房间ID"];
        return;
    }
    if (_roomIDTF.text.integerValue == 0) {
        [self showToast:@"房间ID不能等于0"];
        return;
    }
    
    [NSUserDefaults.standardUserDefaults setObject:_roomIDTF.text forKey:@"ENTERROOMID"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    TTManager.roomID = _roomIDTF.text;
    TTManager.uid = _uid;
    TTTRtcClientRole clientRole = _roleSelectedBtn.tag - 100;
    TTManager.me.clientRole = clientRole;
    TTManager.me.uid = _uid;
    TTManager.me.mutedSelf = false;
    TTManager.me.isMe = YES;
    
    [TTManager.rtcEngine setLogFilter:TTTRtc_LogFilter_Debug];
    if (_roleSelectedBtn.tag == 101) {//主播页面
        [self performSegueWithIdentifier:@"Live" sender:nil];
    } else {//观众页面
        [self performSegueWithIdentifier:@"Audience" sender:nil];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}



@end
