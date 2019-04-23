/*****************************************************************************
 * rqdMediaPlaybackController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <caro # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *          Winston Weinert <winston # ml1 dot net>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackController.h"
#import "UIDevice+rqdMedia.h"
#import <AVFoundation/AVFoundation.h>
//#import "rqdMediaPlayerDisplayController.h"
#import "rqdMediaConstants.h"
#import "rqdMediaRemoteControlService.h"
#import "VLCMetadata.h"
#import "TVHChannel.h"

NSString *const rqdMediaPlaybackControllerPlaybackDidStart = @"rqdMediaPlaybackControllerPlaybackDidStart";
NSString *const rqdMediaPlaybackControllerPlaybackDidPause = @"rqdMediaPlaybackControllerPlaybackDidPause";
NSString *const rqdMediaPlaybackControllerPlaybackDidResume = @"rqdMediaPlaybackControllerPlaybackDidResume";
NSString *const rqdMediaPlaybackControllerPlaybackDidStop = @"rqdMediaPlaybackControllerPlaybackDidStop";
NSString *const rqdMediaPlaybackControllerPlaybackMetadataDidChange = @"rqdMediaPlaybackControllerPlaybackMetadataDidChange";
NSString *const rqdMediaPlaybackControllerPlaybackDidFail = @"rqdMediaPlaybackControllerPlaybackDidFail";
NSString *const rqdMediaPlaybackControllerPlaybackPositionUpdated = @"rqdMediaPlaybackControllerPlaybackPositionUpdated";

typedef NS_ENUM(NSUInteger, rqdMediaAspectRatio) {
    rqdMediaAspectRatioDefault = 0,
    rqdMediaAspectRatioFillToScreen,
    rqdMediaAspectRatioFourToThree,
    rqdMediaAspectRatioSixteenToNine,
    rqdMediaAspectRatioSixteenToTen,
};

@interface rqdMediaPlaybackController () <VLCMediaPlayerDelegate, VLCMediaDelegate, rqdMediaRemoteControlServiceDelegate>
{
//    是否横屏
    BOOL isHorizontalcreen;
    rqdMediaRemoteControlService *_remoteControlService;
    VLCMediaPlayer *_mediaPlayer;
    VLCMediaListPlayer *_listPlayer;
    BOOL _playerIsSetup;
    BOOL _shouldResumePlaying;
    BOOL _sessionWillRestart;

    NSString *_pathToExternalSubtitlesFile;
    int _itemInMediaListToBePlayedFirst;
    NSTimer *_sleepTimer;

    NSUInteger _currentAspectRatio;
    BOOL _isInFillToScreen;

    UIView *_videoOutputViewWrapper;
    UIView *_actualVideoOutputView;
    UIView *_preBackgroundWrapperView;

    BOOL _needsMetadataUpdate;
    BOOL _mediaWasJustStarted;
    BOOL _recheckForExistingThumbnail;
    BOOL _externalAudioPlaybackDevicePlugged;

    NSLock *_playbackSessionManagementLock;

    NSMutableArray *_shuffleStack;
    void (^_playbackCompletion)(BOOL success);
}
//@property(nonatomic,strong)TVListChannel *tVListChannel;
@end

@implementation rqdMediaPlaybackController

#pragma mark instance management

+ (rqdMediaPlaybackController *)sharedInstance
{
    static rqdMediaPlaybackController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [rqdMediaPlaybackController new];
    });

    return sharedInstance;
}

- (void)dealloc
{
    _dialogProvider = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // listen to audiosessions and appkit callback
        _externalAudioPlaybackDevicePlugged = [self isExternalAudioPlaybackDevicePlugged];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(audioSessionRouteChange:)
                              name:AVAudioSessionRouteChangeNotification object:nil];

        [defaultCenter addObserver:self selector:@selector(handleInterruption:)
                              name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];

        // appkit because we neeed to know when we go to background in order to stop the video, so that we don't crash
        [defaultCenter addObserver:self selector:@selector(applicationWillResignActive:)
                              name:UIApplicationWillResignActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:)
                              name:UIApplicationDidBecomeActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:)
                              name:UIApplicationDidEnterBackgroundNotification object:nil];

        _metadata = [VLCMetaData new];
        _dialogProvider = [[VLCDialogProvider alloc] initWithLibrary:[VLCLibrary sharedLibrary] customUI:YES];
        _dialogProvider.customRenderer = self;

        _playbackSessionManagementLock = [[NSLock alloc] init];
        _shuffleMode = NO;
        _shuffleStack = [[NSMutableArray alloc] init];

    }
    return self;
}

- (rqdMediaRemoteControlService *)remoteControlService
{
    if (!_remoteControlService) {
        _remoteControlService = [[rqdMediaRemoteControlService alloc] init];
        _remoteControlService.remoteControlServiceDelegate = self;
    }
    return _remoteControlService;
}



#pragma mark - playback management

- (void)openVideoSubTitlesFromFile:(NSString *)pathToFile
{
    [_mediaPlayer addPlaybackSlave:[NSURL fileURLWithPath:pathToFile] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
}

- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(NSString * _Nullable)subsFilePath
{
    self.fullscreenSessionRequested = YES;
    [self playMediaList: mediaList firstIndex: index subtitlesFilePath: subsFilePath completion: nil];
}

- (void)playMediaList:(VLCMediaList *)mediaList firstIndex:(NSInteger)index subtitlesFilePath:(NSString * _Nullable)subsFilePath completion:(void (^ __nullable)(BOOL success))completion
{
    _playbackCompletion = completion;
    self.mediaList = mediaList;
    _itemInMediaListToBePlayedFirst = (int)index;
    _pathToExternalSubtitlesFile = subsFilePath;
    _sessionWillRestart = _playerIsSetup;
    _playerIsSetup ? [self stopPlayback] : [self startPlayback];
}

- (VLCTime *)playedTime
{
    return [_mediaPlayer time];
}

- (void)startPlayback
{
    if (_playerIsSetup) {
        APLog(@"%s: player is already setup, bailing out", __PRETTY_FUNCTION__);
        return;
    }

    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!self.mediaList) {
        APLog(@"%s: no URL and no media list set, stopping playback", __PRETTY_FUNCTION__);
        [_playbackSessionManagementLock unlock];
        [self stopPlayback];
        return;
    }

    /* video decoding permanently fails if we don't provide a UIView to draw into on init
     * hence we provide one which is not attached to any view controller for off-screen drawing
     * and disable video decoding once playback started */
    _actualVideoOutputView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _actualVideoOutputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _actualVideoOutputView.autoresizesSubviews = YES;
   
    _listPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:_actualVideoOutputView];

    /* to enable debug logging for the playback library instance, switch the boolean below
     * note that the library instance used for playback may not necessarily match the instance
     * used for media discovery or thumbnailing */
    _listPlayer.mediaPlayer.libraryInstance.debugLogging = YES;

    _mediaPlayer = _listPlayer.mediaPlayer;
    [_mediaPlayer setDelegate:self];
    if ([[defaults objectForKey:krqdMediaSettingPlaybackSpeedDefaultValue] floatValue] != 0)
        [_mediaPlayer setRate: [[defaults objectForKey:krqdMediaSettingPlaybackSpeedDefaultValue] floatValue]];
    int deinterlace = [[defaults objectForKey:krqdMediaSettingDeinterlace] intValue];
    [_mediaPlayer setDeinterlace:deinterlace withFilter:@"blend"];

    VLCMedia *media = [_mediaList mediaAtIndex:_itemInMediaListToBePlayedFirst];
    [media parseWithOptions:VLCMediaParseLocal];
    media.delegate = self;
    [media addOptions:self.mediaOptionsDictionary];

    [_listPlayer setMediaList:self.mediaList];

    [_listPlayer setRepeatMode:VLCDoNotRepeat];

    [_playbackSessionManagementLock unlock];

    [self _playNewMedia];
}

- (void)_playNewMedia
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    // Set last selected equalizer profile
    unsigned int profile = (unsigned int)[[[NSUserDefaults standardUserDefaults] objectForKey:krqdMediaSettingEqualizerProfile] integerValue];
    [_mediaPlayer resetEqualizerFromProfile:profile];
    [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];

    _mediaWasJustStarted = YES;

    [_mediaPlayer addObserver:self forKeyPath:@"time" options:0 context:nil];
    [_mediaPlayer addObserver:self forKeyPath:@"remainingTime" options:0 context:nil];

    [_mediaPlayer setRendererItem:_renderer];

    [_listPlayer playItemAtNumber:@(_itemInMediaListToBePlayedFirst)];

    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];

    _currentAspectRatio = rqdMediaAspectRatioDefault;
    _mediaPlayer.videoAspectRatio = NULL;
    _mediaPlayer.videoCropGeometry = NULL;

    [[self remoteControlService] subscribeToRemoteCommands];

    if (_pathToExternalSubtitlesFile) {
        /* this could be a path or an absolute string - let's see */
        NSURL *subtitleURL = [NSURL URLWithString:_pathToExternalSubtitlesFile];
        if (!subtitleURL) {
            subtitleURL = [NSURL fileURLWithPath:_pathToExternalSubtitlesFile];
        }
        if (subtitleURL) {
            [_mediaPlayer addPlaybackSlave:subtitleURL type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
        }
    }

    _playerIsSetup = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidStart object:self];
    [_playbackSessionManagementLock unlock];
}

//不退出暂停播放下一个
-(void)stopPlayNext:(NSInteger )Index{
    [_mediaPlayer pause];
//    [self _savePlaybackState];
    [_mediaPlayer stop];
        [_listPlayer playMedia:[self.mediaList mediaAtIndex:Index]];
}

- (void)stopPlayback
{
    BOOL ret = [_playbackSessionManagementLock tryLock];
    if (!ret) {
        APLog(@"%s: locking failed", __PRETTY_FUNCTION__);
        return;
    }

    if (_mediaPlayer) {
        @try {
            [_mediaPlayer removeObserver:self forKeyPath:@"time"];
            [_mediaPlayer removeObserver:self forKeyPath:@"remainingTime"];
        }
        @catch (NSException *exception) {
            APLog(@"we weren't an observer yet");
        }

        if (_mediaPlayer.media) {
            [_mediaPlayer pause];
#if TARGET_OS_IOS
            [self _savePlaybackState];
#endif
            [_mediaPlayer stop];
        }
        _mediaPlayer = nil;
        _listPlayer = nil;
    }
    if (!_sessionWillRestart) {
        _mediaList = nil;
    }
    _playerIsSetup = NO;
    [_shuffleStack removeAllObjects];

    if (_playbackCompletion) {
        BOOL finishedPlaybackWithError = _mediaPlayer.state == VLCMediaPlayerStateError &&  !_sessionWillRestart;
        _playbackCompletion(!finishedPlaybackWithError);
    }

    [[self remoteControlService] unsubscribeFromRemoteCommands];

    [_playbackSessionManagementLock unlock];
    if (!_sessionWillRestart) {
        [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidStop object:self];
    } else {
        _sessionWillRestart = NO;
        [self startPlayback];
    }
}

#if TARGET_OS_IOS

- (void)restoreAudioAndSubtitleTrack
{
    MLFile *item = [MLFile fileForURL:_mediaPlayer.media.url].firstObject;

    if (item) {
        _mediaPlayer.currentAudioTrackIndex = item.lastAudioTrack.intValue;
        _mediaPlayer.currentVideoSubTitleIndex = item.lastSubtitleTrack.intValue;
    }
}

- (void)_savePlaybackState
{
    @try {
        [[MLMediaLibrary sharedMediaLibrary] save];
    }
    @catch (NSException *exception) {
        APLog(@"saving playback state failed");
    }

    NSArray *files = [MLFile fileForURL:_mediaPlayer.media.url];
    MLFile *fileItem = files.firstObject;

    if (!fileItem) {
        APLog(@"couldn't find file, not saving playback progress");
        return;
    }

    @try {
        float position = _mediaPlayer.position;
        fileItem.lastPosition = @(position);
        fileItem.lastAudioTrack = @(_mediaPlayer.currentAudioTrackIndex);
        fileItem.lastSubtitleTrack = @(_mediaPlayer.currentVideoSubTitleIndex);

        if (position > .95)
            return;

        if (_mediaPlayer.hasVideoOut) {
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *newThumbnailPath = [searchPaths.firstObject stringByAppendingPathComponent:@"VideoSnapshots"];
            NSError *error;

            [[NSFileManager defaultManager] createDirectoryAtPath:newThumbnailPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error == nil) {
                newThumbnailPath = [newThumbnailPath stringByAppendingPathComponent:fileItem.objectID.URIRepresentation.lastPathComponent];
                [_mediaPlayer saveVideoSnapshotAt:newThumbnailPath withWidth:0 andHeight:0];
                _recheckForExistingThumbnail = YES;
                [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:.25];
            }
        }
    }
    @catch (NSException *exception) {
        APLog(@"failed to save current media state - file removed?");
    }
}
#endif

#if TARGET_OS_IOS
- (void)_updateStoredThumbnailForFile:(MLFile *)fileItem
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* newThumbnailPath = [searchPaths[0] stringByAppendingPathComponent:@"VideoSnapshots"];
    newThumbnailPath = [newThumbnailPath stringByAppendingPathComponent:fileItem.objectID.URIRepresentation.lastPathComponent];

    if (![fileManager fileExistsAtPath:newThumbnailPath]) {
        if (_recheckForExistingThumbnail) {
            [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:1.];
            _recheckForExistingThumbnail = NO;
        } else
            return;
    }

    UIImage *newThumbnail = [UIImage imageWithContentsOfFile:newThumbnailPath];
    if (!newThumbnail) {
        if (_recheckForExistingThumbnail) {
            [self performSelector:@selector(_updateStoredThumbnailForFile:) withObject:fileItem afterDelay:1.];
            _recheckForExistingThumbnail = NO;
        } else
            return;
    }

    @try {
        [fileItem setComputedThumbnailScaledForDevice:newThumbnail];
    }
    @catch (NSException *exception) {
        APLog(@"updating thumbnail failed");
    }

    [fileManager removeItemAtPath:newThumbnailPath error:nil];
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_mediaWasJustStarted) {
        _mediaWasJustStarted = NO;
#if TARGET_OS_IOS
        if (self.mediaList) {
            NSArray *matches = [MLFile fileForURL:_mediaPlayer.media.url];
            MLFile *item = matches.firstObject;
            [self _recoverLastPlaybackStateOfItem:item];
        }
#else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL bValue = [defaults boolForKey:krqdMediaSettingUseSPDIF];

        if (bValue) {
           _mediaPlayer.audio.passthrough = bValue;
        }
#endif
    }

    if ([self.delegate respondsToSelector:@selector(playbackPositionUpdated:)])
        [self.delegate playbackPositionUpdated:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackPositionUpdated
                                                        object:self];
}

- (NSInteger)mediaDuration
{
    return _mediaPlayer.media.length.intValue;;
}

- (BOOL)isPlaying
{
    return _mediaPlayer.isPlaying;
}

- (BOOL)willPlay
{
    return _mediaPlayer.willPlay;
}

- (VLCRepeatMode)repeatMode
{
    return _listPlayer.repeatMode;
}

- (void)setRepeatMode:(VLCRepeatMode)repeatMode
{
    _listPlayer.repeatMode = repeatMode;
}

- (BOOL)currentMediaHasChapters
{
    return [_mediaPlayer numberOfTitles] > 1 || [_mediaPlayer numberOfChaptersForTitle:_mediaPlayer.currentTitleIndex] > 1;
}

- (BOOL)currentMediaHasTrackToChooseFrom
{
    return [[_mediaPlayer audioTrackIndexes] count] > 2 || [[_mediaPlayer videoSubTitlesIndexes] count] > 1;
}

- (BOOL) isSeekable
{
    return _mediaPlayer.isSeekable;
}

- (NSNumber *)playbackTime
{
    return _mediaPlayer.time.value;
}

- (float)playbackRate
{
    return _mediaPlayer.rate;
}

- (void)setPlaybackRate:(float)playbackRate
{
    [_mediaPlayer setRate:playbackRate];
    _metadata.playbackRate = @(_mediaPlayer.rate);
}

- (void)setAudioDelay:(float)audioDelay
{
    _mediaPlayer.currentAudioPlaybackDelay = 1000.*audioDelay;
}

- (float)audioDelay
{
    return _mediaPlayer.currentAudioPlaybackDelay/1000.;
}

- (float)playbackPosition
{
    return [_mediaPlayer position];
}

- (void)setPlaybackPosition:(float)position
{
    _mediaPlayer.position = position;
}

- (void)setSubtitleDelay:(float)subtitleDeleay
{
    _mediaPlayer.currentVideoSubTitleDelay = 1000.*subtitleDeleay;
}

- (float)subtitleDelay
{
    return _mediaPlayer.currentVideoSubTitleDelay/1000.;
}

- (float)hue
{
    return _mediaPlayer.hue;
}

- (void)setHue:(float)hue
{
    _mediaPlayer.hue = hue;
}

- (float)contrast
{
    return _mediaPlayer.contrast;
}

- (void)setContrast:(float)contrast
{
    _mediaPlayer.contrast = contrast;
}

- (float)brightness
{
    return _mediaPlayer.brightness;
}

- (void)setBrightness:(float)brightness
{
    _mediaPlayer.brightness = brightness;
}

- (float)saturation
{
    return _mediaPlayer.saturation;
}

- (void)setSaturation:(float)saturation
{
    _mediaPlayer.saturation = saturation;
}

- (void)setGamma:(float)gamma
{
    _mediaPlayer.gamma = gamma;
}

- (float)gamma
{
    return _mediaPlayer.gamma;
}

- (void)resetFilters
{
    _mediaPlayer.hue = 0.;
    _mediaPlayer.contrast = 1.;
    _mediaPlayer.brightness = 1.;
    _mediaPlayer.saturation = 1.;
    _mediaPlayer.gamma = 1.;
}

- (void)toggleRepeatMode
{
    if (_listPlayer.repeatMode == VLCRepeatAllItems) {
        _listPlayer.repeatMode = VLCDoNotRepeat;
    } else {
        _listPlayer.repeatMode += 1;
    }
}

- (NSInteger)indexOfCurrentAudioTrack
{
    return [_mediaPlayer.audioTrackIndexes indexOfObject:@(_mediaPlayer.currentAudioTrackIndex)];
}

- (NSInteger)indexOfCurrentSubtitleTrack
{
    return [_mediaPlayer.videoSubTitlesIndexes indexOfObject:@(_mediaPlayer.currentVideoSubTitleIndex)];
}

- (NSInteger)indexOfCurrentChapter
{
    return _mediaPlayer.currentChapterIndex;
}

- (NSInteger)indexOfCurrentTitle
{
    return _mediaPlayer.currentTitleIndex;
}

- (NSInteger)numberOfAudioTracks
{
    return _mediaPlayer.audioTrackIndexes.count;
}

- (NSInteger)numberOfVideoSubtitlesIndexes
{
    return _mediaPlayer.videoSubTitlesIndexes.count;
}

- (NSInteger)numberOfTitles
{
    return  [_mediaPlayer numberOfTitles];
}

- (NSInteger)numberOfChaptersForCurrentTitle
{
    return [_mediaPlayer numberOfChaptersForTitle:_mediaPlayer.currentTitleIndex];
}

- (NSString *)videoSubtitleNameAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.videoSubTitlesNames.count)
        return _mediaPlayer.videoSubTitlesNames[index];
    return nil;
}

- (NSString *)audioTrackNameAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackNames.count)
        return _mediaPlayer.audioTrackNames[index];
    return nil;
}

- (NSDictionary *)titleDescriptionsDictAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.titleDescriptions.count)
        return _mediaPlayer.titleDescriptions[index];
    return nil;
}

- (NSDictionary *)chapterDescriptionsDictAtIndex:(NSInteger)index
{
    NSArray *chapterDescriptions = [_mediaPlayer chapterDescriptionsOfTitle:_mediaPlayer.currentTitleIndex];
    if (index >= 0 && index < chapterDescriptions.count)
        return chapterDescriptions[index];
    return nil;
}

- (void)selectAudioTrackAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.audioTrackIndexes.count) {
        //we can cast this cause we won't have more than 2 million audiotracks
        _mediaPlayer.currentAudioTrackIndex = [_mediaPlayer.audioTrackIndexes[index] intValue];
    }
}

- (void)selectVideoSubtitleAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _mediaPlayer.videoSubTitlesIndexes.count) {
        _mediaPlayer.currentVideoSubTitleIndex = [_mediaPlayer.videoSubTitlesIndexes[index] intValue];
    }
}

- (void)selectTitleAtIndex:(NSInteger)index
{
    if (index >= 0 && index < [_mediaPlayer numberOfTitles]) {
        //we can cast this cause we won't have more than 2 million titles
        _mediaPlayer.currentTitleIndex = (int)index;
    }
}

- (void)selectChapterAtIndex:(NSInteger)index
{
    if (index >= 0 && index < [self numberOfChaptersForCurrentTitle]) {
        //we can cast this cause we won't have more than 2 million chapters
        _mediaPlayer.currentChapterIndex = (int)index;
    }
}

- (void)shortJumpForward
{
    [_mediaPlayer shortJumpForward];
}

- (void)shortJumpBackward
{
    [_mediaPlayer shortJumpBackward];
}

- (VLCTime *)remainingTime
{
    return [_mediaPlayer remainingTime];
}

- (void)setAudioPassthrough:(BOOL)shouldPass
{
    _mediaPlayer.audio.passthrough = shouldPass;
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    VLCMediaPlayerState currentState = _mediaPlayer.state;

    switch (currentState) {
        case VLCMediaPlayerStateBuffering: {
            /* attach delegate */
            _mediaPlayer.media.delegate = self;

            /* on-the-fly values through hidden API */
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [_mediaPlayer performSelector:@selector(setTextRendererFont:) withObject:[defaults objectForKey:krqdMediaSettingSubtitlesFont]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontSize:) withObject:[defaults objectForKey:krqdMediaSettingSubtitlesFontSize]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontColor:) withObject:[defaults objectForKey:krqdMediaSettingSubtitlesFontColor]];
            [_mediaPlayer performSelector:@selector(setTextRendererFontForceBold:) withObject:[defaults objectForKey:krqdMediaSettingSubtitlesBoldFont]];
        } break;

        case VLCMediaPlayerStateError: {
            APLog(@"Playback failed");
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidFail object:self];
            });
            _sessionWillRestart = NO;
            [self stopPlayback];
        } break;
        case VLCMediaPlayerStateEnded:
        case VLCMediaPlayerStateStopped: {
            [_listPlayer.mediaList lock];
            NSUInteger listCount = _listPlayer.mediaList.count;
            [_listPlayer.mediaList unlock];
            if ([_listPlayer.mediaList indexOfMedia:_mediaPlayer.media] == listCount - 1 && self.repeatMode == VLCDoNotRepeat) {
                _sessionWillRestart = NO;
                [self stopPlayback];
                return;
            }
        } break;
        case VLCMediaPlayerStateESAdded: {
#if TARGET_OS_IOS
            [self restoreAudioAndSubtitleTrack];
#endif
        } break;
        default:
            break;
    }

    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackController:)])
        [self.delegate mediaPlayerStateChanged:currentState
                                     isPlaying:_mediaPlayer.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackController:self];

    [self setNeedsMetadataUpdate];
}

#pragma mark - playback controls
- (void)playPause
{
    [_mediaPlayer isPlaying] ? [self pause] : [self play];
}

- (void)play
{
    [_listPlayer play];
    [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidResume object:self];
}

- (void)pause
{
    [_listPlayer pause];
#if TARGET_OS_IOS
    [self _savePlaybackState];
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidPause object:self];
}

- (void)next
{
    NSInteger mediaListCount = _mediaList.count;

#if TARGET_OS_IOS
    if (self.repeatMode != VLCRepeatCurrentItem && mediaListCount > 2 && _shuffleMode) {

        NSNumber *nextIndex;
        NSUInteger currentIndex = [_mediaList indexOfMedia:_listPlayer.mediaPlayer.media];

        //Reached end of playlist
        if (_shuffleStack.count + 1 == mediaListCount) {
            if ([self repeatMode] == VLCDoNotRepeat)
                return;
            [_shuffleStack removeAllObjects];
        }

        [_shuffleStack addObject:[NSNumber numberWithUnsignedInteger:currentIndex]];
        do {
            nextIndex = [NSNumber numberWithUnsignedInt:arc4random_uniform((uint32_t)mediaListCount)];
        } while (currentIndex == nextIndex.unsignedIntegerValue || [_shuffleStack containsObject:nextIndex]);

        [_listPlayer playItemAtNumber:[NSNumber numberWithUnsignedInteger:nextIndex.unsignedIntegerValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:self];

        return;
    }
#endif

    if (mediaListCount > 1) {
        [_listPlayer next];
        [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:self];
    } else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:krqdMediaSettingPlaybackForwardSkipLength];
        NSLog(@"%d",skipLength.intValue);
        [_mediaPlayer jumpForward:skipLength.intValue];
    }
}

- (void)previous
{
    if (_mediaList.count > 1) {
        [_listPlayer previous];
        [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:self];
    }
    else {
        NSNumber *skipLength = [[NSUserDefaults standardUserDefaults] valueForKey:krqdMediaSettingPlaybackBackwardSkipLength];
        [_mediaPlayer jumpBackward:skipLength.intValue];
    }
}


- (void)jumpForward:(int)interval
{
    [_mediaPlayer jumpForward:interval];
}

- (void)jumpBackward:(int)interval
{
    [_mediaPlayer jumpBackward:interval];
}

- (UIScreen *)currentScreen
{
    return [[UIDevice currentDevice] rqdMediaHasExternalDisplay] ? [UIScreen screens][1] : [UIScreen mainScreen];
}

- (void)switchToFillToScreen
{
    UIScreen *screen = [self currentScreen];
    CGSize screenSize = screen.bounds.size;

    CGSize videoSize = _mediaPlayer.videoSize;

    CGFloat ar = videoSize.width / (float)videoSize.height;
    CGFloat dar = screenSize.width / (float)screenSize.height;

    CGFloat scale;

    if (dar >= ar) {
        scale = screenSize.width / (float)videoSize.width;
    } else {
        scale = screenSize.height / (float)videoSize.height;
    }

    // Multiplied by screen.scale in consideration of pt to px
    _mediaPlayer.scaleFactor = scale * screen.scale;
    _isInFillToScreen = YES;
}

- (void)switchIPhoneXFullScreen
{
    if (_isInFillToScreen) {
        const char *previousAspectRatio = _currentAspectRatio == rqdMediaAspectRatioDefault ? NULL : [[self stringForAspectRatio:_currentAspectRatio] UTF8String];
        _mediaPlayer.videoAspectRatio = (char *)previousAspectRatio;
        _mediaPlayer.scaleFactor = 0;
        _isInFillToScreen = NO;
    } else {
        [self switchToFillToScreen];
    }
}

- (void)switchAspectRatio
{
    _currentAspectRatio = _currentAspectRatio == rqdMediaAspectRatioSixteenToTen ? rqdMediaAspectRatioDefault : _currentAspectRatio + 1;
    switch (_currentAspectRatio) {
        case rqdMediaAspectRatioDefault:
            _mediaPlayer.scaleFactor = 0;
            _mediaPlayer.videoAspectRatio = NULL;
            _mediaPlayer.videoCropGeometry = NULL;
            break;
        case rqdMediaAspectRatioFillToScreen:
            // Reset aspect ratio only with aspectRatio button since we want to keep
            // the user ratio with double tap.
            _mediaPlayer.videoAspectRatio = NULL;
            [self switchToFillToScreen];
            break;
        case rqdMediaAspectRatioFourToThree:
        case rqdMediaAspectRatioSixteenToTen:
        case rqdMediaAspectRatioSixteenToNine:
            _mediaPlayer.scaleFactor = 0;
            _mediaPlayer.videoCropGeometry = NULL;
            _mediaPlayer.videoAspectRatio = (char *)[[self stringForAspectRatio:_currentAspectRatio] UTF8String];
    }

    if ([self.delegate respondsToSelector:@selector(showStatusMessage:forPlaybackController:)]) {
        [self.delegate showStatusMessage:[NSString stringWithFormat:NSLocalizedString(@"AR_CHANGED", nil), [self stringForAspectRatio:_currentAspectRatio]] forPlaybackController:self];
    }
}

- (NSString *)stringForAspectRatio:(rqdMediaAspectRatio)ratio
{
    switch (ratio) {
            case rqdMediaAspectRatioFillToScreen:
            return NSLocalizedString(@"FILL_TO_SCREEN", nil);
            case rqdMediaAspectRatioDefault:
            return NSLocalizedString(@"DEFAULT", nil);
            case rqdMediaAspectRatioFourToThree:
            return @"4:3";
            case rqdMediaAspectRatioSixteenToTen:
            return @"16:10";
            case rqdMediaAspectRatioSixteenToNine:
            return @"16:9";
        default:
            NSAssert(NO, @"this shouldn't happen");
    }
}

- (void)setVideoTrackEnabled:(BOOL)enabled
{
    if (!enabled)
        _mediaPlayer.currentVideoTrackIndex = -1;
    else if (_mediaPlayer.currentVideoTrackIndex == -1) {
        for (NSNumber *trackId in _mediaPlayer.videoTrackIndexes) {
            if ([trackId intValue] != -1) {
                _mediaPlayer.currentVideoTrackIndex = [trackId intValue];
                break;
            }
        }
    }
}

- (void)setVideoOutputView:(UIView *)videoOutputView
{
    if (videoOutputView) {
        if ([_actualVideoOutputView superview] != nil)
            [_actualVideoOutputView removeFromSuperview];

        _actualVideoOutputView.frame = (CGRect){CGPointZero, videoOutputView.frame.size};

        [self setVideoTrackEnabled:true];

        [videoOutputView addSubview:_actualVideoOutputView];
        [_actualVideoOutputView layoutSubviews];
        [_actualVideoOutputView updateConstraints];
        [_actualVideoOutputView setNeedsLayout];
    } else
        [_actualVideoOutputView removeFromSuperview];
    _videoOutputViewWrapper = videoOutputView;
}

- (UIView *)videoOutputView
{
    return _videoOutputViewWrapper;
}

#pragma mark - 360 Support
#if !TARGET_OS_TV
- (BOOL)updateViewpoint:(CGFloat)yaw pitch:(CGFloat)pitch roll:(CGFloat)roll fov:(CGFloat)fov absolute:(BOOL)absolute
{
    //adjusting the values
    if (fabs(yaw) > 180) {
        yaw = yaw > 0 ? yaw - 360 : yaw + 360;
    }
    if (fabs(roll) > 180) {
        roll = roll > 0 ? roll - 360 : roll + 360;
    }
    if (fabs(pitch) > 90) {
        pitch = pitch > 0 ? pitch - 180 : pitch + 180;
    }
    return [_mediaPlayer updateViewpoint:yaw pitch:pitch roll:roll fov:fov absolute:absolute];
}

- (CGFloat)yaw
{
    return _mediaPlayer.yaw;
}

- (CGFloat)pitch
{
    return _mediaPlayer.pitch;
}

- (CGFloat)roll
{
    return _mediaPlayer.roll;
}

- (CGFloat)fov
{
    return _mediaPlayer.fov;
}

- (BOOL)currentMediaIs360Video
{
    return [self currentMediaProjection] == VLCMediaProjectionEquiRectangular;
}

- (NSInteger)currentMediaProjection
{
    VLCMedia *media = [_mediaPlayer media];
    NSInteger currentVideoTrackIndex = [_mediaPlayer currentVideoTrackIndex];

    if (media && currentVideoTrackIndex >= 0) {
        NSArray *tracksInfo = media.tracksInformation;
        for (NSDictionary *track in tracksInfo) {
            if ([track[VLCMediaTracksInformationType] isEqualToString:VLCMediaTracksInformationTypeVideo]) {
                return [track[VLCMediaTracksInformationVideoProjection] integerValue];
            }
        }
    }
    return -1;
}
#endif

#pragma mark - equalizer

- (void)setAmplification:(CGFloat)amplification forBand:(unsigned int)index
{
    if (!_mediaPlayer.equalizerEnabled)
        [_mediaPlayer setEqualizerEnabled:YES];

    [_mediaPlayer setAmplification:amplification forBand:index];

    // For some reason we have to apply again preamp to apply change
    [_mediaPlayer setPreAmplification:[_mediaPlayer preAmplification]];
}

- (CGFloat)amplificationOfBand:(unsigned int)index
{
    return [_mediaPlayer amplificationOfBand:index];
}

- (NSArray *)equalizerProfiles
{
    return _mediaPlayer.equalizerProfiles;
}

- (void)resetEqualizerFromProfile:(unsigned int)profile
{
    [[NSUserDefaults standardUserDefaults] setObject:@(profile) forKey:krqdMediaSettingEqualizerProfile];
    [_mediaPlayer resetEqualizerFromProfile:profile];
}

- (void)setPreAmplification:(CGFloat)preAmplification
{
    if (!_mediaPlayer.equalizerEnabled)
        [_mediaPlayer setEqualizerEnabled:YES];

    [_mediaPlayer setPreAmplification:preAmplification];
}

- (CGFloat)preAmplification
{
    return [_mediaPlayer preAmplification];
}

#pragma mark - AVAudioSession Notification Observers

- (void)handleInterruption:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;

    if (!userInfo || !userInfo[AVAudioSessionInterruptionTypeKey]) {
        return;
    }

    NSUInteger interruptionType = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        [_mediaPlayer pause];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded
               && [userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue] == AVAudioSessionInterruptionOptionShouldResume) {
        [_mediaPlayer play];
    }
}

- (BOOL)isExternalAudioPlaybackDevicePlugged
{
    /* check what output device is currently connected
     * this code assumes that everything which is not a builtin speaker, must be external */
    NSArray *outputs = [[AVAudioSession sharedInstance] currentRoute].outputs;
    AVAudioSessionPortDescription *outputDescription = outputs.firstObject;
    return ![outputDescription.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker];
}

- (void)audioSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSInteger routeChangeReason = [[userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange)
        return;

    BOOL externalAudioPlaybackDevicePlugged = [self isExternalAudioPlaybackDevicePlugged];

    if (_externalAudioPlaybackDevicePlugged && !externalAudioPlaybackDevicePlugged && [_mediaPlayer isPlaying]) {
        APLog(@"Pausing playback as previously plugged external audio playback device was removed");
        [_mediaPlayer pause];
#if TARGET_OS_IOS
        [self _savePlaybackState];
#endif
        [[NSNotificationCenter defaultCenter] postNotificationName:rqdMediaPlaybackControllerPlaybackDidPause object:self];
    }
    _externalAudioPlaybackDevicePlugged = externalAudioPlaybackDevicePlugged;
}

#pragma mark - Managing the media item

- (VLCMedia *)currentlyPlayingMedia
{
    return _mediaPlayer.media;
}

#pragma mark - metadata handling
- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action
{
    [_mediaPlayer performNavigationAction:action];
}
- (void)mediaDidFinishParsing:(VLCMedia *)aMedia
{
    [self setNeedsMetadataUpdate];
}

- (void)mediaMetaDataDidChange:(VLCMedia*)aMedia
{
    [self setNeedsMetadataUpdate];
}

- (void)setNeedsMetadataUpdate
{
    if (_needsMetadataUpdate == NO) {
        _needsMetadataUpdate = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_metadata updateMetadataFromMediaPlayer:_mediaPlayer];
            _needsMetadataUpdate = NO;
            if ([self.delegate respondsToSelector:@selector(displayMetadataForPlaybackController:metadata:)])
                [self.delegate displayMetadataForPlaybackController:self metadata:_metadata];
        });
    }
}

#if TARGET_OS_IOS
- (void)_recoverLastPlaybackStateOfItem:(MLFile *)item
{
    if (item) {
        CGFloat lastPosition = .0;
        NSInteger duration = 0;

        if (item.lastPosition) {
            lastPosition = item.lastPosition.floatValue;
        }
        
        duration = item.duration.intValue;

        if (lastPosition < .95 && _mediaPlayer.position < lastPosition) {
            NSInteger continuePlayback;
            if ([item isAlbumTrack] || [item isSupportedAudioFile])
                continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:krqdMediaSettingContinueAudioPlayback] integerValue];
            else
                continuePlayback = [[[NSUserDefaults standardUserDefaults] objectForKey:krqdMediaSettingContinuePlayback] integerValue];

            if (continuePlayback == 1) {
                [self setPlaybackPosition:lastPosition];
            } else if (continuePlayback == 0) {
                rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"CONTINUE_PLAYBACK", nil)
                                                                  message:[NSString stringWithFormat:NSLocalizedString(@"CONTINUE_PLAYBACK_LONG", nil), item.title]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        otherButtonTitles:NSLocalizedString(@"BUTTON_CONTINUE", nil), nil];
                alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                    if (!cancelled) {
                        [self setPlaybackPosition:lastPosition];
                    }
                };
                [alert show];
            }
        }
    }
}
#endif

- (void)recoverDisplayedMetadata
{
    if ([self.delegate respondsToSelector:@selector(displayMetadataForPlaybackController:metadata:)])
        [self.delegate displayMetadataForPlaybackController:self metadata:_metadata];
}

- (void)recoverPlaybackState
{
    if ([self.delegate respondsToSelector:@selector(mediaPlayerStateChanged:isPlaying:currentMediaHasTrackToChooseFrom:currentMediaHasChapters:forPlaybackController:)])
        [self.delegate mediaPlayerStateChanged:_mediaPlayer.state
                                     isPlaying:self.isPlaying
              currentMediaHasTrackToChooseFrom:self.currentMediaHasTrackToChooseFrom
                       currentMediaHasChapters:self.currentMediaHasChapters
                         forPlaybackController:self];
    if ([self.delegate respondsToSelector:@selector(prepareForMediaPlayback:)])
        [self.delegate prepareForMediaPlayback:self];
}

- (void)scheduleSleepTimerWithInterval:(NSTimeInterval)timeInterval
{
    if (_sleepTimer) {
        [_sleepTimer invalidate];
        _sleepTimer = nil;
    }
    _sleepTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(stopPlayback) userInfo:nil repeats:NO];
}

- (BOOL)isPlayingOnExternalScreen
{
    return (_renderer || [[UIDevice currentDevice] rqdMediaHasExternalDisplay]);
}

#pragma mark - background interaction

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
#if TARGET_OS_IOS
    [self _savePlaybackState];
#endif
    if (![self isPlayingOnExternalScreen]
        && ![[[NSUserDefaults standardUserDefaults] objectForKey:krqdMediaSettingContinueAudioInBackgroundKey] boolValue]) {
        if ([_mediaPlayer isPlaying]) {
            [_mediaPlayer pause];
            _shouldResumePlaying = YES;
        }
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    _preBackgroundWrapperView = _videoOutputViewWrapper;

    if (!_renderer && _mediaPlayer.audioTrackIndexes.count > 0)
        [self setVideoTrackEnabled:false];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (_preBackgroundWrapperView) {
        [self setVideoOutputView:_preBackgroundWrapperView];
        _preBackgroundWrapperView = nil;
    }

    [self setVideoTrackEnabled:true];

    if (_shouldResumePlaying) {
        _shouldResumePlaying = NO;
        [_listPlayer play];
    }
}
#pragma mark - remoteControlDelegate

- (void)remoteControlServiceHitPause:(rqdMediaRemoteControlService *)rcs
{
    [_listPlayer pause];
}

- (void)remoteControlServiceHitPlay:(rqdMediaRemoteControlService *)rcs
{
    [_listPlayer play];
}

- (void)remoteControlServiceTogglePlayPause:(rqdMediaRemoteControlService *)rcs
{
    [self playPause];
}

- (void)remoteControlServiceHitStop:(rqdMediaRemoteControlService *)rcs
{
    //TODO handle stop playback entirely
    [_listPlayer stop];
}

- (BOOL)remoteControlServiceHitPlayNextIfPossible:(rqdMediaRemoteControlService *)rcs
{
    //TODO This doesn't handle shuffle or repeat yet
    return [_listPlayer next];
}

- (BOOL)remoteControlServiceHitPlayPreviousIfPossible:(rqdMediaRemoteControlService *)rcs
{
    //TODO This doesn't handle shuffle or repeat yet
    return [_listPlayer previous];
}

- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs jumpForwardInSeconds:(NSTimeInterval)seconds
{
    [_mediaPlayer jumpForward:seconds];
}

- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs jumpBackwardInSeconds:(NSTimeInterval)seconds
{
    [_mediaPlayer jumpBackward:seconds];
}

- (NSInteger)remoteControlServiceNumberOfMediaItemsinList:(rqdMediaRemoteControlService *)rcs
{
    return _mediaList.count;
}

- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs setPlaybackRate:(CGFloat)playbackRate
{
    self.playbackRate = playbackRate;
}

- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs setCurrentPlaybackTime:(NSTimeInterval)playbackTime
{
    float positionDiff = playbackTime - [self.metadata.elapsedPlaybackTime floatValue];
    [_mediaPlayer jumpForward:positionDiff];
}

#pragma mark - helpers

- (NSDictionary *)mediaOptionsDictionary
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return @{ krqdMediaSettingNetworkCaching : [defaults objectForKey:krqdMediaSettingNetworkCaching],
              krqdMediaSettingStretchAudio : [[defaults objectForKey:krqdMediaSettingStretchAudio] boolValue] ? krqdMediaSettingStretchAudioOnValue : krqdMediaSettingStretchAudioOffValue,
              krqdMediaSettingTextEncoding : [defaults objectForKey:krqdMediaSettingTextEncoding],
              krqdMediaSettingSkipLoopFilter : [defaults objectForKey:krqdMediaSettingSkipLoopFilter],
              krqdMediaSettingHardwareDecoding : [defaults objectForKey:krqdMediaSettingHardwareDecoding]};
}

#pragma mark - Renderer
- (void)setRenderer:(VLCRendererItem * __nullable)renderer
{
    _renderer = renderer;
    [_mediaPlayer setRendererItem:_renderer];
}
@end
