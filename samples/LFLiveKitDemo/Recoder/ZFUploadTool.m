//
//  ZFUploadTool.m
//  Recoder
//
//  Created by 张帆 on 2018/12/6.
//  Copyright © 2018 admin. All rights reserved.
//

#import "ZFUploadTool.h"
#import <LFLiveKit.h>

inline static NSString *formatedSpeed(float bytes, float elapsed_milli) {
    if (elapsed_milli <= 0) {
        return @"N/A";
    }
    if (bytes <= 0) {
        return @"0 KB/s";
    }
    float bytes_per_sec = ((float)bytes) * 1000.f /  elapsed_milli;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000 / 1000];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}


@interface ZFUploadTool () <LFLiveSessionDelegate>

@property (nonatomic, strong) LFLiveDebug *debugInfo;
@property (nonatomic, strong) LFLiveSession *session;
@property (nonatomic, assign) BOOL mic;
@property (nonatomic, assign) int frameQuality;
@property (nonatomic, copy) NSString *url;

@end

@implementation ZFUploadTool

+ (instancetype)shareTool {
    static dispatch_once_t onceToken;
    static ZFUploadTool *tool = nil;
    dispatch_once(&onceToken, ^{
        tool = [[ZFUploadTool alloc] init];
    });
    return tool;
}

- (void)prepareToStart:(NSDictionary *)dict {
    _url = dict[@"endpointURL"];
    _mic = [dict[@"mic"] boolValue];
    _mic = YES;
    _frameQuality = [dict[@"frameQuality"] intValue]; // 0 高 1中 2低
    if (!_url) {
        _url = @"rtmp://192.168.45.174:1935/mobile/123";
    }
    [self lf];
}
- (void)lf {
    LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
    stream.url = _url;
//    stream.videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High3 outputImageOrientation:UIInterfaceOrientationLandscapeRight];
//    stream.audioConfiguration = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_Medium];
//    stream.videoConfiguration.videoSize = CGSizeMake(UIScreen.mainScreen.bounds.size.height, UIScreen.mainScreen.bounds.size.width);
    
    [self.session startLive:stream];
}

#pragma mark -- Getter Setter
- (LFLiveSession *)session {
    if (_session == nil) {
        
        LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_High];
        audioConfiguration.numberOfChannels = 1;
        LFLiveVideoConfiguration *videoConfiguration;
       
        videoConfiguration = [LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_High4];
        videoConfiguration.videoSize = CGSizeMake((NSInteger)(UIScreen.mainScreen.bounds.size.width/UIScreen.mainScreen.bounds.size.height * 1920), 1920);
        videoConfiguration.encoderType = LFVideoH265Encoder;
        
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration captureType:_mic? LFLiveInputMaskAll:LFLiveInputMaskVideo];
        
        _session.delegate = self;
        _session.showDebugInfo = YES;
        
    }
    return _session;
}

-(void)stop {
    [self.session stopLive];
}


- (void)sendAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_mic) {
        [self.session pushAudioBuffer:sampleBuffer];
    }
    
}

- (void)sendVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.session pushVideoBuffer:sampleBuffer];
}

#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
//    NSLog(@"liveStateDidChange: %ld", state);
    switch (state) {
        case LFLiveReady:
            NSLog(@"未连接");
            break;
        case LFLivePending:
            NSLog(@"连接中");
            break;
        case LFLiveStart:
            NSLog(@"已连接");
            break;
        case LFLiveError:
            NSLog(@"连接错误");
            break;
        case LFLiveStop:
            NSLog(@"未连接");
            break;
        default:
            break;
    }
}

/** live debug info callback */
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
//    NSString *speed = formatedSpeed(debugInfo.currentBandwidth, debugInfo.elapsedMilli);
    
}
/** callback socket errorcode */
- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"errorCode: %ld", errorCode);
}



@end
