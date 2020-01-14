
# 单向直播转互动直播

随着移动互联网技术的发展，网络直播作为新兴的社交方式已引发新一轮媒介革命，迅速成为新媒体营销的新阵地，如何在直播竞争中取得领先优势，成为各个平台寻求差异化的动力，“互动直播”成为了直播发展的趋势。通过视频连麦，用户之间可以进行视频互动，达到更深层次的超越语言文字的交流。
互动直播对比传统单向直播，可以演变更多的互动玩法，大幅提升直播的趣味性与娱乐性。

## 典型场景
互动直播与单向直播不同，赋予了普通观众“露脸发声”的权利，低延时的通信网络，主播可以实现与连麦观众的双向互动，在直播房间里的其他观众也可以观看主播和连麦观众互动的过程。在互动的时候还可以加上道具、美颜等滤镜，与陌生人进行视频互动聊天，是社交娱乐的典型场景。
基于三体云的互动直播技术，可以将原来的传统单向直播快速转变为互动直播场景，通过技术深度优化实现传统直播转换到互动连麦场景下的无缝切换。

# 示例程序

#### 准备工作
1. 下载TTTLiveEngineKit.framework(https://pan.baidu.com/s/1Ki3rxni3rlGAk3mnxfSULQ)，放入ThirdPart下；
2. 登录三体云官网 [http://dashboard.3ttech.cn/index/login]() 注册体验账号，进入控制台新建自己的应用并获取APPID；
3. 下载DEMO源码，将APPID填入代码中相应的位置并体验效果。

# 实现步骤

### 直推

1，创建TTT音视频引擎对象
	[sharedEngineWithAppId](http://www.3ttech.cn/index.php?menu=72&type=iOS#sharedEngineWithAppId)
2， 设置视频参数
  	[setVideoProfile](http://www.3ttech.cn/index.php?menu=72&type=iOS#setVideoProfile)
3, 启动本地视频预览
	[startPreview](http://www.3ttech.cn/index.php?menu=72&type=iOS#startPreview)
4, 设置本地视频显示属性
	[setupLocalVideo](http://www.3ttech.cn/index.php?menu=72&type=iOS#setupLocalVideo)
5, 开始rtmp推流
	[startRtmpPublish](http://www.3ttech.cn/index.php?menu=72&type=iOS#startRtmpPublish)
6, 停止rtmp推流
	[stopRtmpPublish](http://www.3ttech.cn/index.php?menu=72&type=iOS#stopRtmpPublish)
	|| [leaveChannel](http://www.3ttech.cn/index.php?menu=72&type=iOS#leaveChannel)


### 上麦

1， 设置频道模式
 	[setChannelProfile](http://www.3ttech.cn/index.php?menu=72&type=iOS#setChannelProfile)
2,	设置用户角色
	[setClientRole](http://www.3ttech.cn/index.php?menu=72&type=iOS#setClientRole) 
3，	设置编码格式
	[setPreferAudioCodec](http://www.3ttech.cn/index.php?menu=72&type=iOS#setPreferAudioCodec) 
4， 设置SDK的CDN推流地址
	[configPublisher](http://www.3ttech.cn/index.php?menu=72&type=iOS#configPublisher) 
5,  上麦
	[upChannelByKey]
6, 	如果有远端用户，设置远端用户显示属性
	[setupRemoteVideo](http://www.3ttech.cn/index.php?menu=72&type=iOS#setupRemoteVideo)

### 下麦转直推

1， 下麦
	[downChannelWithRtmpURL]

### 结束推流

1,  离开频道/结束直推
	[leaveChannel](http://www.3ttech.cn/index.php?menu=72&type=iOS#leaveChannel)


### 拉流
1， 创建TTT音视频引擎对象
	[sharedEngineWithAppId](http://www.3ttech.cn/index.php?menu=72&type=iOS#sharedEngineWithAppId)
2，	设置拉流地址,创建TTT拉流引擎
	[livePlayerWithDefaultOptionsWithURL]
3,  开启拉流
	[livePlayerPlay]

### 拉流转上麦
1， 设置频道模式
 	[setChannelProfile](http://www.3ttech.cn/index.php?menu=72&type=iOS#setChannelProfile)
2， 设置用户角色
	[setClientRole](http://www.3ttech.cn/index.php?menu=72&type=iOS#setClientRole) 
3， 设置视频参数
  	[setVideoProfile](http://www.3ttech.cn/index.php?menu=72&type=iOS#setVideoProfile)
4,	上麦
	[upChannelByKey]
5,  启动本地视频预览
	[startPreview](http://www.3ttech.cn/index.php?menu=72&type=iOS#startPreview)
6,  设置本地视频显示属性
	[setupLocalVideo](http://www.3ttech.cn/index.php?menu=72&type=iOS#setupLocalVideo)

### 下麦转拉流
1， 下麦
	[downChannelWithRtmpURL]

### 退出
1，  退出/结束拉流
	[leaveChannel](http://www.3ttech.cn/index.php?menu=72&type=iOS#leaveChannel)


### ps
1， 只考虑1对1的连麦场景

2,  推流地址**最后一位数字**大的会取代小的，拉流地址不包含**?**及后面的部分

3，  此场下，拉流转直播时不需要设置远端主播的显示属性

4， leaveChannel 可以关闭所有情景，包括推流，拉流，退出房间

# iOS工程配置

SDK包含“TTTLiveEngineKit.framework”

**framewotk只支持真机，不支持模拟器**

工程已做如下配置，直接运行工程

1. 设置Bitcode为NO
2. 设置后台音频模式
3. 导入系统库

* libxml2.tbd
* libc++.tbd
* libz.tbd
* libsqlite3.tbd
* ReplayKit.framework
* CoreTelephony.framework
* SystemConfiguration.framework






