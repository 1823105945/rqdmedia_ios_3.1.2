/*****************************************************************************
 * rqdMediaMiniPlaybackView.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaMiniPlaybackView.h"
#import "VLCPlaybackController.h"
#import "rqdMediaPlayerDisplayController.h"
#import "VLCMetadata.h"
#import "rqdMedia_iOS-Swift.h"

@interface rqdMediaMiniPlaybackView () <UIGestureRecognizerDelegate>
{
    UIImageView *_artworkView;
    UIView *_videoView;
    UIButton *_previousButton;
    UIButton *_playPauseButton;
    UIButton *_nextButton;
    UIButton *_expandButton;
    UILabel *_metaDataLabel;
    UITapGestureRecognizer *_tapRecognizer;
    UIStackView *_stackView;
}

@end

@implementation rqdMediaMiniPlaybackView

- (instancetype)initWithFrame:(CGRect)viewFrame
{
    self = [super initWithFrame:viewFrame];
    if (self) {
        [self setupSubviews];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(appBecameActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
    }
    return self;
}

- (void)setupSubviews
{
    CGFloat buttonSize = 44.;
    CGFloat videoSize = 60.;
    CGFloat padding = 10.;

    _artworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _artworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _artworkView.clipsToBounds = YES;
    _artworkView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    _artworkView.opaque = YES;
    [self addSubview:_artworkView];

    _videoView = [[UIView alloc] initWithFrame:CGRectZero];
    [_videoView setClipsToBounds:YES];
    _videoView.userInteractionEnabled = NO;
    _videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_videoView];

    _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_expandButton setImage:[UIImage imageNamed:@"ratioIcon"] forState:UIControlStateNormal];
    _expandButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_expandButton addTarget:self action:@selector(pushFullPlaybackView:) forControlEvents:UIControlEventTouchUpInside];
    _expandButton.accessibilityLabel = NSLocalizedString(@"FULLSCREEN_PLAYBACK", nil);

    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setImage:[UIImage imageNamed:@"forwardIcon"] forState:UIControlStateNormal];
    _nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_nextButton addTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventTouchUpInside];
    _nextButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);

    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playPauseButton setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    _playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_playPauseButton addTarget:self action:@selector(playPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.accessibilityLabel = NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil);
    _playPauseButton.accessibilityHint = NSLocalizedString(@"LONGPRESS_TO_STOP", nil);
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseLongPress:)];
    [_playPauseButton addGestureRecognizer:longPressRecognizer];

    _previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_previousButton setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [_previousButton sizeToFit];
    _previousButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_previousButton addTarget:self action:@selector(previousAction:) forControlEvents:UIControlEventTouchUpInside];
    _previousButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);

    _metaDataLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _metaDataLabel.font = [UIFont systemFontOfSize:12.];
    _metaDataLabel.textColor = [UIColor rqdMediaLightTextColor];
    _metaDataLabel.numberOfLines = 0;
    _metaDataLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_metaDataLabel];

    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_previousButton, _playPauseButton, _nextButton, _expandButton]];
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    _stackView.distribution = UIStackViewDistributionFillEqually;
    [self addSubview:_stackView];

    id<rqdMediaLayoutAnchorContainer> guide = self;
    if (@available(iOS 11.0, *)) {
        guide = self.safeAreaLayoutGuide;
    }

    [NSLayoutConstraint activateConstraints:@[
                                              [_artworkView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [_artworkView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_artworkView.rightAnchor constraintEqualToAnchor:_metaDataLabel.leftAnchor constant:-padding],
                                              [_artworkView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
                                              [_artworkView.widthAnchor constraintEqualToConstant:videoSize],
                                              [_artworkView.heightAnchor constraintEqualToAnchor:_artworkView.widthAnchor],

                                              [_videoView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
                                              [_videoView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_videoView.rightAnchor constraintEqualToAnchor:_metaDataLabel.leftAnchor constant:-padding],
                                              [_videoView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
                                              [_videoView.widthAnchor constraintEqualToConstant:videoSize],
                                              [_videoView.heightAnchor constraintEqualToAnchor:_videoView.widthAnchor],

                                              [_metaDataLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_metaDataLabel.rightAnchor constraintLessThanOrEqualToAnchor:_stackView.leftAnchor constant:- padding],
                                              [_metaDataLabel.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
                                              [_previousButton.widthAnchor constraintEqualToConstant:buttonSize],

                                              [_stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
                                              [_stackView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
                                              ]];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized)];
    _tapRecognizer.delegate = self;
    [self addGestureRecognizer:_tapRecognizer];

#if TARGET_OS_IOS
    _tapRecognizer.numberOfTouchesRequired = 1;
#endif
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    rqdMediaPlayerDisplayController *pdc = [rqdMediaPlayerDisplayController sharedInstance];
    if (pdc.displayMode == rqdMediaPlayerDisplayControllerDisplayModeMiniplayer) {
        [[rqdMediaPlaybackController sharedInstance] recoverDisplayedMetadata];
    }
}

- (void)tapRecognized
{
    [self pushFullPlaybackView:nil];
}

- (void)previousAction:(id)sender
{
    [[rqdMediaPlaybackController sharedInstance] previous];
}

- (void)playPauseAction:(id)sender
{
    [[rqdMediaPlaybackController sharedInstance] playPause];
}

- (void)playPauseLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [_playPauseButton setImage:[UIImage imageNamed:@"stopIcon"] forState:UIControlStateNormal];
            break;
        case UIGestureRecognizerStateEnded:
            [[rqdMediaPlaybackController sharedInstance] stopPlayback];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self updatePlayPauseButton];
            break;
        default:
            break;
    }
}

- (void)nextAction:(id)sender
{
    [[rqdMediaPlaybackController sharedInstance] next];
}

- (void)pushFullPlaybackView:(id)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(showFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (void)updatePlayPauseButton
{
    const BOOL isPlaying = [rqdMediaPlaybackController sharedInstance].isPlaying;
    UIImage *playPauseImage = isPlaying ? [UIImage imageNamed:@"pauseIcon"] : [UIImage imageNamed:@"playIcon"];
    [_playPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

- (void)prepareForMediaPlayback:(rqdMediaPlaybackController *)controller
{
    [self updatePlayPauseButton];
    controller.delegate = self;
    [controller recoverDisplayedMetadata];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(rqdMediaPlaybackController *)controller
{
    [self updatePlayPauseButton];
}

- (void)displayMetadataForPlaybackController:(rqdMediaPlaybackController *)controller metadata:(VLCMetaData *)metadata
{
    _videoView.hidden = YES;
    if (metadata.isAudioOnly) {
        _artworkView.contentMode = UIViewContentModeScaleAspectFill;
        _artworkView.image = metadata.artworkImage?: [UIImage imageNamed:@"no-artwork"];
    } else {
        _artworkView.image = nil;
        rqdMediaPlayerDisplayController *pdc = [rqdMediaPlayerDisplayController sharedInstance];
        if (pdc.displayMode == rqdMediaPlayerDisplayControllerDisplayModeMiniplayer) {
            _videoView.hidden = false;
            controller.videoOutputView = _videoView;
        }
    }

    NSString *metaDataString;
    if (metadata.artist)
        metaDataString = metadata.artist;
    if (metadata.albumName)
        metaDataString = [metaDataString stringByAppendingFormat:@" — %@", metadata.albumName];
    if (metaDataString)
        metaDataString = [metaDataString stringByAppendingFormat:@"\n%@", metadata.title];
    else
        metaDataString = metadata.title;

    _metaDataLabel.text = metaDataString;
}

@end
