/*****************************************************************************
 * rqdMediaMovieViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <caro # videolan.org>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Ahmad Harb <harb.dev.leb # gmail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Filipe Cabecinhas <rqdmedia # filcab dot net>
 *          Marc Etcheverry <marc # taplightsoftware dot com>
 *          Christopher Loessl <cloessl # x-berg dot de>
 *          Sylver Bruneau <sylver.bruneau # gmail dot com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaMovieViewController.h"
#import "rqdMediaEqualizerView.h"
#import "rqdMediaMultiSelectionMenuView.h"
#import "VLCPlaybackController.h"
#import "UIDevice+rqdMedia.h"
#import "VLCTimeNavigationTitleView.h"
#import "rqdMediaPlayerDisplayController.h"
#import "rqdMediaAppDelegate.h"
#import "rqdMediaStatusLabel.h"
#import "rqdMediaMovieViewControlPanelView.h"
#import "rqdMediaSlider.h"
#import "VLCLibraryViewController.h"
#import "rqdMediaTrackSelectorView.h"
#import "VLCMetadata.h"
#import "UIDevice+rqdMedia.h"
#import "rqdMedia_iOS-Swift.h"
#import "TVListChannel.h"
#import "Masonry.h"
#import "Header.h"

#define FORWARD_SWIPE_DURATION 30
#define BACKWARD_SWIPE_DURATION 10
#define SHORT_JUMP_DURATION 10

#define ZOOM_SENSITIVITY 5.f
#define DEFAULT_FOV 80.f
#define MAX_FOV 150.f
#define MIN_FOV 20.f

typedef NS_ENUM(NSInteger, rqdMediaPanType) {
  rqdMediaPanTypeNone,
  rqdMediaPanTypeBrightness,
  rqdMediaPanTypeSeek,
  rqdMediaPanTypeVolume,
  rqdMediaPanTypeProjection
};

@interface rqdMediaMovieViewController () <UIGestureRecognizerDelegate, rqdMediaMultiSelectionViewDelegate, rqdMediaEqualizerViewUIDelegate, rqdMediaPlaybackControllerDelegate, rqdMediaDeviceMotionDelegate, VLCRendererDiscovererManagerDelegate>
{
    BOOL _controlsHidden;
    BOOL _videoFiltersHidden;
    BOOL _playbackSpeedViewHidden;

    UIActionSheet *_subtitleActionSheet;
    UIActionSheet *_audiotrackActionSheet;

    NSTimer *_idleTimer;

    BOOL _viewAppeared;
    BOOL _displayRemainingTime;
    BOOL _positionSet;
    BOOL _isScrubbing;
    BOOL _interfaceIsLocked;
    BOOL _audioOnly;

    BOOL _volumeGestureEnabled;
    BOOL _playPauseGestureEnabled;
    BOOL _brightnessGestureEnabled;
    BOOL _seekGestureEnabled;
    BOOL _closeGestureEnabled;
    BOOL _variableJumpDurationEnabled;
    BOOL _playbackWillClose;
    BOOL _isTapSeeking;
    rqdMediaMovieJumpState _previousJumpState;
    VLCMediaPlayerState _previousPlayerStateWasPaused;

    UIPinchGestureRecognizer *_pinchRecognizer;
    rqdMediaPanType _currentPanType;
    UIPanGestureRecognizer *_panRecognizer;
    UISwipeGestureRecognizer *_swipeRecognizerLeft;
    UISwipeGestureRecognizer *_swipeRecognizerRight;
    UISwipeGestureRecognizer *_swipeRecognizerUp;
    UISwipeGestureRecognizer *_swipeRecognizerDown;
    UITapGestureRecognizer *_tapRecognizer;
    UITapGestureRecognizer *_tapOnVideoRecognizer;
    UITapGestureRecognizer *_tapToToggleiPhoneXRatioRecognizer;
    UITapGestureRecognizer *_tapToSeekRecognizer;

    UIButton *_doneButton;

    rqdMediaTrackSelectorView *_trackSelectorContainer;

    rqdMediaEqualizerView *_equalizerView;
    rqdMediaMultiSelectionMenuView *_multiSelectionView;

    rqdMediaPlaybackController *_vpc;

    UIView *_sleepTimerContainer;
    UIDatePicker *_sleepTimeDatePicker;
    NSTimer *_sleepCountDownTimer;

    NSInteger _mediaDuration;
    NSInteger _numberOfTapSeek;

    rqdMediaDeviceMotion *_deviceMotion;
    CGFloat _fov;
    CGPoint _saveLocation;
    CGSize _screenPixelSize;
    UIInterfaceOrientation _lockedOrientation;

    UIStackView *_navigationBarStackView;
    UIButton *_rendererButton;
    BOOL hideViewList;
}
@property(nonatomic,strong)VLCMediaList *mediaList;
@property(nonatomic,strong)TVListChannel *tVListChannel;
@property (nonatomic, strong) rqdMediaMovieViewControlPanelView *controllerPanel;
@property (nonatomic, strong) UIPopoverController *masterPopoverController;
@property(nonatomic,strong)UIButton *recordingutton;
@property (nonatomic, strong) IBOutlet rqdMediaPlayingExternallyView *playingExternalView;

@end

@implementation rqdMediaMovieViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{krqdMediaShowRemainingTime : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect rect;

    _vpc = [rqdMediaPlaybackController sharedInstance];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    self.videoFilterView.hidden = YES;
    _videoFiltersHidden = YES;
    _hueLabel.text = NSLocalizedString(@"VFILTER_HUE", nil);
    _hueSlider.accessibilityLabel = _hueLabel.text;
    _contrastLabel.text = NSLocalizedString(@"VFILTER_CONTRAST", nil);
    _contrastSlider.accessibilityLabel = _contrastLabel.text;
    _brightnessLabel.text = NSLocalizedString(@"VFILTER_BRIGHTNESS", nil);
    _brightnessSlider.accessibilityLabel = _brightnessLabel.text;
    _saturationLabel.text = NSLocalizedString(@"VFILTER_SATURATION", nil);
    _saturationSlider.accessibilityLabel = _saturationLabel.text;
    _gammaLabel.text = NSLocalizedString(@"VFILTER_GAMMA", nil);
    _gammaSlider.accessibilityLabel = _gammaLabel.text;
    _playbackSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SPEED", nil);
    _playbackSpeedSlider.accessibilityLabel = _playbackSpeedLabel.text;
    _audioDelayLabel.text = NSLocalizedString(@"AUDIO_DELAY", nil);
    _audioDelaySlider.accessibilityLabel = _audioDelayLabel.text;
    _spuDelayLabel.text = NSLocalizedString(@"SPU_DELAY", nil);
    _spuDelaySlider.accessibilityLabel = _spuDelayLabel.text;

    _resetVideoFilterButton.accessibilityLabel = NSLocalizedString(@"VIDEO_FILTER_RESET_BUTTON", nil);
    _sleepTimerButton.accessibilityLabel = NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil);
    [_sleepTimerButton setTitle:NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil) forState:UIControlStateNormal];

    _multiSelectionView = [[rqdMediaMultiSelectionMenuView alloc] init];
    _multiSelectionView.delegate = self;
    _multiSelectionView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _multiSelectionView.hidden = YES;
    [self.view addSubview:_multiSelectionView];

    _scrubHelpLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HELP", nil);

    self.playbackSpeedView.hidden = YES;
    _playbackSpeedViewHidden = YES;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self
               selector:@selector(appBecameActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(playbackDidStop:)
                   name:rqdMediaPlaybackControllerPlaybackDidStop
                 object:nil];

    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text =self.subheadingLable.text= @"";

    _movieView.userInteractionEnabled = NO;

    [self setupGestureRecognizers];

    _isTapSeeking = NO;
    _previousJumpState = rqdMediaMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    rect = self.resetVideoFilterButton.frame;
    rect.origin.y = rect.origin.y + 5.;
    self.resetVideoFilterButton.frame = rect;

    [self.movieView setAccessibilityLabel:NSLocalizedString(@"VO_VIDEOPLAYER_TITLE", nil)];
    [self.movieView setAccessibilityHint:NSLocalizedString(@"VO_VIDEOPLAYER_DOUBLETAP", nil)];

    _trackSelectorContainer = [[rqdMediaTrackSelectorView alloc] initWithFrame:CGRectZero];
    _trackSelectorContainer.hidden = YES;
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
        _trackSelectorContainer.hidden = YES;
    };
    _trackSelectorContainer.completionHandler = completionBlock;
    _trackSelectorContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_trackSelectorContainer];

    _equalizerView = [[rqdMediaEqualizerView alloc] initWithFrame:CGRectMake(0, 0, 450., 240.)];
    _equalizerView.delegate = [rqdMediaPlaybackController sharedInstance];
    _equalizerView.UIdelegate = self;
    _equalizerView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    _equalizerView.hidden = YES;
    [self.view addSubview:_equalizerView];

    //Sleep Timer initialization
    [self sleepTimerInitializer];
    [self setupControlPanel];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    _screenPixelSize = CGSizeMake(screenBounds.size.width, screenBounds.size.height);

    [self setupConstraints];
    [self setupRendererDiscovererManager];
    [self.view addSubview:self.tVListChannel ];
    [self.view addSubview:self.recordingutton];
    [self.recordingutton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(100);
        make.right.mas_equalTo(-10);
        make.width.height.mas_equalTo(30);
    }];
//    [self layer];
}



-(UIButton *)recordingutton{
    if (!_recordingutton) {
        _recordingutton=[UIButton buttonWithType:(UIButtonTypeCustom)];
        [_recordingutton setImage:[UIImage imageNamed:@"RecordingImage"] forState:(UIControlStateNormal)];
        [_recordingutton setImage:[UIImage imageNamed:@"InrecordingImage"] forState:(UIControlStateSelected)];
        [_recordingutton addTarget:self action:@selector(recordingClock) forControlEvents:(UIControlEventTouchUpInside)];
        _recordingutton.hidden=YES;
    }
    return _recordingutton;
}

-(void)recordingClock{
    if (self.tVListChannel.currentPlayChannel>=self.tVListChannel.channels.count) {
        return;
    }
    id TvHchannel=self.tVListChannel.channels[self.tVListChannel.currentPlayChannel];
    
    self.subheadingLable.text=@"";
    if ([TvHchannel isKindOfClass:[TVHChannel class]]) {
        TVHChannel *channel=(TVHChannel *)TvHchannel;
        TVHEpg *currentEPG = [channel nextPrograms:3][0];
        [self addRecordMoreItemsToTVHeadend:currentEPG];
    }
}

- (void)addRecordMoreItemsToTVHeadend:(TVHEpg *)epg {
    // for our program
        if ( ! [epg schedstate] ) {
            [epg addRecording];
        }
    [TVHAnalytics sendEventWithCategory:@"uiAction"
                             withAction:@"recordings"
                              withLabel:@"addRecording"
                              withValue:[NSNumber numberWithInt:0]];
}


- (void)setupGestureRecognizers
{
    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible:)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];

    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinchRecognizer.delegate = self;

    if ([[UIDevice currentDevice] isiPhoneX]) {
        _tapToToggleiPhoneXRatioRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:_vpc action:@selector(switchIPhoneXFullScreen)];
        _tapToToggleiPhoneXRatioRecognizer.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:_tapToToggleiPhoneXRatioRecognizer];
    } else {
        _tapToSeekRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSeekRecognized:)];
        [_tapToSeekRecognizer setNumberOfTapsRequired:2];
        [self.view addGestureRecognizer:_tapToSeekRecognizer];
        [_tapOnVideoRecognizer requireGestureRecognizerToFail:_tapToSeekRecognizer];
    }
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayPause)];
    [_tapRecognizer setNumberOfTouchesRequired:2];
    _currentPanType = rqdMediaPanTypeNone;
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecognized:)];
    [_panRecognizer setMinimumNumberOfTouches:1];
    [_panRecognizer setMaximumNumberOfTouches:1];

    _swipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    _swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    _swipeRecognizerUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerUp.direction = UISwipeGestureRecognizerDirectionUp;
    _swipeRecognizerUp.numberOfTouchesRequired = 2;
    _swipeRecognizerDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRecognized:)];
    _swipeRecognizerDown.direction = UISwipeGestureRecognizerDirectionDown;
    _swipeRecognizerDown.numberOfTouchesRequired = 2;

    [self.view addGestureRecognizer:_pinchRecognizer];
    [self.view addGestureRecognizer:_swipeRecognizerLeft];
    [self.view addGestureRecognizer:_swipeRecognizerRight];
    [self.view addGestureRecognizer:_swipeRecognizerUp];
    [self.view addGestureRecognizer:_swipeRecognizerDown];
    [self.view addGestureRecognizer:_panRecognizer];
    [self.view addGestureRecognizer:_tapRecognizer];

    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerLeft];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerRight];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerUp];
    [_panRecognizer requireGestureRecognizerToFail:_swipeRecognizerDown];

    _panRecognizer.delegate = self;
    _swipeRecognizerRight.delegate = self;
    _swipeRecognizerLeft.delegate = self;
    _swipeRecognizerUp.delegate = self;
    _swipeRecognizerDown.delegate = self;
    _tapRecognizer.delegate = self;
    _tapToSeekRecognizer.delegate = self;
}

- (void)setupControlPanel
{
    _controllerPanel = [[rqdMediaMovieViewControlPanelView alloc] initWithFrame:CGRectZero];
    [_controllerPanel.bwdButton addTarget:self action:@selector(backward:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.fwdButton addTarget:self action:@selector(forward:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.playPauseButton addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.moreActionsButton addTarget:self action:@selector(moreActions:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.playbackSpeedButton addTarget:self action:@selector(showPlaybackSpeedView) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.trackSwitcherButton addTarget:self action:@selector(switchTrack:) forControlEvents:UIControlEventTouchUpInside];
    [_controllerPanel.videoFilterButton addTarget:self action:@selector(videoFilterToggle:) forControlEvents:UIControlEventTouchUpInside];

    // HACK: get the slider from volume view
    UISlider *volumeSlider = nil;
    for (id aView in _controllerPanel.volumeView.subviews){
        if ([aView isKindOfClass:[UISlider class]]){
            volumeSlider = (UISlider *)aView;
            break;
        }
    }
    [volumeSlider addTarget:self action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];

    _controllerPanel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_controllerPanel];
}

- (void)setupConstraints
{
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[panel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"panel":_controllerPanel}];

    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[panel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"panel":_controllerPanel}];
    [self.view addConstraints:hConstraints];
    [self.view addConstraints:vConstraints];

    //constraint within _trackSelectorContainer is setting it's height to the tableviews contentview
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:2.0/3.0 constant:0];
    widthConstraint.priority = UILayoutPriorityRequired - 1;
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:420.0],
                             widthConstraint,
                             [NSLayoutConstraint constraintWithItem:_trackSelectorContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:2.0/3.0 constant:0],
                             ];
    [NSLayoutConstraint activateConstraints:constraints];

}

- (void)setupNavigationbar
{
    _doneButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_doneButton addTarget:self action:@selector(closePlayback:) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:NSLocalizedString(@"BUTTON_DONE", nil) forState:UIControlStateNormal];
    [_doneButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    _doneButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.timeNavigationTitleView = [[[NSBundle mainBundle] loadNibNamed:@"VLCTimeNavigationTitleView" owner:self options:nil] objectAtIndex:0];
    self.timeNavigationTitleView.translatesAutoresizingMaskIntoConstraints = NO;

    if (_vpc.renderer != nil) {
        [_rendererButton setSelected:YES];
    }

    _navigationBarStackView = [[UIStackView alloc] init];
    _navigationBarStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationBarStackView.spacing = 8;
    _navigationBarStackView.axis = UILayoutConstraintAxisHorizontal;
    _navigationBarStackView.alignment = UIStackViewAlignmentCenter;
    [_navigationBarStackView addArrangedSubview:_doneButton];
    [_navigationBarStackView addArrangedSubview:_timeNavigationTitleView];
    [_navigationBarStackView addArrangedSubview:_rendererButton];

    [self.navigationController.navigationBar addSubview:_navigationBarStackView];

    NSObject *guide = self.navigationController.navigationBar;
    if (@available(iOS 11.0, *)) {
        guide = self.navigationController.navigationBar.safeAreaLayoutGuide;
    }

    [NSLayoutConstraint activateConstraints:@[
                                              [NSLayoutConstraint constraintWithItem:_navigationBarStackView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
                                              [NSLayoutConstraint constraintWithItem:_navigationBarStackView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeft multiplier:1 constant:8],
                                              [NSLayoutConstraint constraintWithItem:_navigationBarStackView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeRight multiplier:1 constant:-8],
                                              [NSLayoutConstraint constraintWithItem:_navigationBarStackView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                                              [NSLayoutConstraint constraintWithItem:_navigationBarStackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                                              [NSLayoutConstraint constraintWithItem:_timeNavigationTitleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_navigationBarStackView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]
                                              ]];
}

- (void)resetVideoFiltersSliders
{
    _brightnessSlider.value = 1.;
    _contrastSlider.value = 1.;
    _hueSlider.value = 0.;
    _saturationSlider.value = 1.;
    _gammaSlider.value = 1.;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _vpc.delegate = self;
    _lockedOrientation = UIInterfaceOrientationPortrait;
    [_vpc recoverPlaybackState];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self setupNavigationbar];
    /* reset audio meta data views */
    self.artworkImageView.image = nil;
    self.trackNameLabel.text = nil;
    self.artistNameLabel.text = nil;
    self.albumNameLabel.text = nil;
    self.subheadingLable.text=nil;
    [self setControlsHidden:NO animated:animated];

    [self updateDefaults];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDefaults) name:NSUserDefaultsDidChangeNotification object:nil];

    VLCRendererDiscovererManager *manager = [VLCRendererDiscovererManager sharedInstance];
    manager.presentingViewController = self;
    manager.delegate = self;
    if ([_vpc isPlayingOnExternalScreen]) {
         [self showOnDisplay:_playingExternalView.displayView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewAppeared = YES;
    _playbackWillClose = NO;

    [_vpc recoverDisplayedMetadata];
    [self resetVideoFiltersSliders];
    _vpc.videoOutputView = self.movieView;
    _multiSelectionView.repeatMode = _vpc.repeatMode;
    _multiSelectionView.shuffleMode = _vpc.isShuffleMode;

    //Media is loaded in the media player, checking the projection type and configuring accordingly.
    [self setupForMediaProjection];
    [VLCRendererDiscovererManager.sharedInstance start];
}

- (void)viewDidLayoutSubviews
{
    CGRect equalizerRect = _equalizerView.frame;
    equalizerRect.origin.x = CGRectGetMidX(self.view.bounds) - CGRectGetWidth(equalizerRect)/2.0;
    equalizerRect.origin.y = CGRectGetMidY(self.view.bounds) - CGRectGetHeight(equalizerRect)/2.0;
    _equalizerView.frame = equalizerRect;

    CGRect multiSelectionFrame;
    CGRect controllerPanelFrame = _controllerPanel.frame;;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
        _multiSelectionView.frame = multiSelectionFrame;
        _multiSelectionView.showsEqualizer = YES;
        [self layer];
        return;
    }

    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        _multiSelectionView.showsEqualizer = YES;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
        [self layer];
    } else {
        _multiSelectionView.showsEqualizer = NO;
        multiSelectionFrame = (CGRect){CGPointMake(0., 0.), [_multiSelectionView proposedDisplaySize]};
        multiSelectionFrame.origin.x = controllerPanelFrame.size.width - multiSelectionFrame.size.width;
        multiSelectionFrame.origin.y = controllerPanelFrame.origin.y - multiSelectionFrame.size.height;
        [self layer];
    }
    _multiSelectionView.frame = multiSelectionFrame;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_vpc.videoOutputView == self.movieView) {
        _vpc.videoOutputView = nil;
    }

    _viewAppeared = NO;
    if (_idleTimer) {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];

    // hide filter UI for next run
    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (_interfaceIsLocked)
        [self toggleUILock];
    // reset tap to seek values
    _isTapSeeking = NO;
    _previousJumpState = rqdMediaMovieJumpStateDefault;
    _numberOfTapSeek = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSUserDefaults standardUserDefaults] setBool:_displayRemainingTime forKey:krqdMediaShowRemainingTime];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.deviceMotion stopDeviceMotion];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self setControlsHidden:YES animated:flag];
    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)updateDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (!_playbackWillClose) {
        _displayRemainingTime = [[defaults objectForKey:krqdMediaShowRemainingTime] boolValue];
        [self updateTimeDisplayButton];
    }

    _volumeGestureEnabled = [[defaults objectForKey:krqdMediaSettingVolumeGesture] boolValue];
    _playPauseGestureEnabled = [[defaults objectForKey:krqdMediaSettingPlayPauseGesture] boolValue];
    _brightnessGestureEnabled = [[defaults objectForKey:krqdMediaSettingBrightnessGesture] boolValue];
    _seekGestureEnabled = [[defaults objectForKey:krqdMediaSettingSeekGesture] boolValue];
    _closeGestureEnabled = [[defaults objectForKey:krqdMediaSettingCloseGesture] boolValue];
    _variableJumpDurationEnabled = [[defaults objectForKey:krqdMediaSettingVariableJumpDuration] boolValue];
}

#pragma mark - Initializer helper

- (void)sleepTimerInitializer
{
    /* add sleep timer UI */
    _sleepTimerContainer = [[rqdMediaFrostedGlasView alloc] initWithFrame:CGRectMake(0., 0., 300., 200.)];
    _sleepTimerContainer.center = self.view.center;
    _sleepTimerContainer.clipsToBounds = YES;
    _sleepTimerContainer.layer.cornerRadius = 5;
    _sleepTimerContainer.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    //Layers used to create a separator for the buttons.
    CALayer *horizontalSeparator = [CALayer layer];
    horizontalSeparator.frame = CGRectMake(0., 162., 300., 1.);
    horizontalSeparator.backgroundColor = [UIColor rqdMediaLightTextColor].CGColor;

    CALayer *verticalSeparator = [CALayer layer];
    verticalSeparator.frame = CGRectMake(150., 162., 1., 48.);
    verticalSeparator.backgroundColor = [UIColor rqdMediaLightTextColor].CGColor;

    _sleepTimeDatePicker = [[UIDatePicker alloc] init];
    _sleepTimeDatePicker.opaque = NO;
    _sleepTimeDatePicker.backgroundColor = [UIColor clearColor];
    _sleepTimeDatePicker.tintColor = [UIColor rqdMediaLightTextColor];
    _sleepTimeDatePicker.frame = CGRectMake(0., 0., 300., 162.);
    _sleepTimeDatePicker.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

    [_sleepTimerContainer addSubview:_sleepTimeDatePicker];
    [_sleepTimerContainer.layer addSublayer:horizontalSeparator];
    [_sleepTimerContainer.layer addSublayer:verticalSeparator];

    UIButton *cancelSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(0., 162., 150., 48.)];
    cancelSleepTimer.backgroundColor = [UIColor clearColor];
    [cancelSleepTimer setTitle:NSLocalizedString(@"BUTTON_RESET", nil) forState:UIControlStateNormal];
    [cancelSleepTimer setTintColor:[UIColor rqdMediaLightTextColor]];
    [cancelSleepTimer setTitleColor:[UIColor rqdMediaDarkTextShadowColor] forState:UIControlStateHighlighted];
    [cancelSleepTimer addTarget:self action:@selector(sleepTimerCancel:) forControlEvents:UIControlEventTouchDown];
    cancelSleepTimer.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    [_sleepTimerContainer addSubview:cancelSleepTimer];

    UIButton *confirmSleepTimer = [[UIButton alloc] initWithFrame:CGRectMake(150., 162., 150., 48.)];
    confirmSleepTimer.backgroundColor = [UIColor clearColor];
    [confirmSleepTimer setTitle:NSLocalizedString(@"BUTTON_SET", nil) forState:UIControlStateNormal];
    [confirmSleepTimer setTintColor:[UIColor rqdMediaLightTextColor]];
    [confirmSleepTimer setTitleColor:[UIColor rqdMediaDarkTextShadowColor] forState:UIControlStateHighlighted];
    [confirmSleepTimer addTarget:self action:@selector(sleepTimerAction:) forControlEvents:UIControlEventTouchDown];
    confirmSleepTimer.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 10, 0);
    [_sleepTimerContainer addSubview:confirmSleepTimer];

    /* adapt the date picker style to suit our needs */
    [_sleepTimeDatePicker setValue:[UIColor whiteColor] forKeyPath:@"textColor"];
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    [invocation setArgument:&no atIndex:2];
    [invocation invokeWithTarget:_sleepTimeDatePicker];

    if (_sleepTimerContainer.subviews.count > 0) {
        NSArray *subviewsOfSubview = [_sleepTimeDatePicker.subviews[0] subviews];
        NSUInteger subviewCount = subviewsOfSubview.count;
        for (NSUInteger x = 0; x < subviewCount; x++) {
            if ([subviewsOfSubview[x] isKindOfClass:[UILabel class]])
                [subviewsOfSubview[x] setTextColor:[UIColor rqdMediaLightTextColor]];
        }
    }
    _sleepTimeDatePicker.datePickerMode = UIDatePickerModeCountDownTimer;
    _sleepTimeDatePicker.minuteInterval = 1;
    _sleepTimeDatePicker.minimumDate = [NSDate date];
    _sleepTimeDatePicker.countDownDuration = 1200.;

    [self.view addSubview:_sleepTimerContainer];
}

#pragma mark - controls visibility

- (NSArray *)itemsForInterfaceLock
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray: @[_pinchRecognizer,
                                                                     _panRecognizer,
                                                                     _tapRecognizer,
                                                                     _doneButton,
                                                                     _timeNavigationTitleView.minimizePlaybackButton,
                                                                     _timeNavigationTitleView.positionSlider,
                                                                     _timeNavigationTitleView.aspectRatioButton,
                                                                     _controllerPanel.playbackSpeedButton,
                                                                     _controllerPanel.trackSwitcherButton,
                                                                     _controllerPanel.bwdButton,
                                                                     _controllerPanel.playPauseButton,
                                                                     _controllerPanel.fwdButton,
                                                                     _controllerPanel.videoFilterButton,
                                                                     _multiSelectionView.equalizerButton,
                                                                     _multiSelectionView.chapterSelectorButton,
                                                                     _multiSelectionView.repeatButton,
                                                                     _multiSelectionView.shuffleButton,
                                                                     _controllerPanel.volumeView,
                                                                     _rendererButton]];

    [[UIDevice currentDevice] isiPhoneX] ? [items addObject:_tapToToggleiPhoneXRatioRecognizer]
                                         : [items addObject:_tapToSeekRecognizer];

    return [items copy];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    CGFloat diff = DEFAULT_FOV * -(ZOOM_SENSITIVITY * recognizer.velocity / _screenPixelSize.width);

    if ([_vpc currentMediaIs360Video]) {
        [self zoom360Video:diff];
    } else if (recognizer.velocity < 0. && _closeGestureEnabled) {
        [self minimizePlayback:nil];
    }
}

- (void)zoom360Video:(CGFloat)zoom
{
    if ([_vpc updateViewpoint:0 pitch:0 roll:0 fov:zoom absolute:NO]) {
        //clamp Fov between min and max fov
        _fov = MAX(MIN(_fov + zoom, MAX_FOV), MIN_FOV);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"%@",touch.view);
    if (touch.view != self.view)
        return NO;
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated
{
    _controlsHidden = hidden;
    CGFloat alpha = _controlsHidden? 0.0f: 1.0f;

    if (!_controlsHidden) {
        self.navigationController.navigationBar.alpha = 0.0;
        self.navigationController.navigationBar.hidden = NO;
        _controllerPanel.alpha = 0.0f;
        _controllerPanel.hidden = !_videoFiltersHidden;
        _videoFilterView.alpha = 0.0f;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.alpha = 0.0f;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        _trackSelectorContainer.alpha = 0.0f;
        _trackSelectorContainer.hidden = YES;
        _equalizerView.alpha = 0.0f;
        _equalizerView.hidden = YES;
        if (_sleepTimerContainer) {
            _sleepTimerContainer.alpha = 0.0f;
            _sleepTimerContainer.hidden = YES;
        }
        _multiSelectionView.alpha = 0.0f;
        _multiSelectionView.hidden = YES;

        _artistNameLabel.hidden = NO;
        _albumNameLabel.hidden = NO;
        _trackNameLabel.hidden = NO;
        _subheadingLable.hidden=NO;
    }

    void (^animationBlock)() = ^() {
        self.navigationController.navigationBar.alpha = alpha;
        _controllerPanel.alpha = alpha;
        _videoFilterView.alpha = alpha;
        _playbackSpeedView.alpha = alpha;
        _trackSelectorContainer.alpha = alpha;
        _equalizerView.alpha = alpha;
        _multiSelectionView.alpha = alpha;
        if (_sleepTimerContainer)
            _sleepTimerContainer.alpha = alpha;

        CGFloat metaInfoAlpha = _audioOnly ? 1.0f : alpha;
        _artistNameLabel.alpha = metaInfoAlpha;
        _albumNameLabel.alpha = metaInfoAlpha;
        _trackNameLabel.alpha = metaInfoAlpha;
        _subheadingLable.alpha=metaInfoAlpha;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _controllerPanel.hidden = _videoFiltersHidden ? _controlsHidden : NO;
        _videoFilterView.hidden = _videoFiltersHidden;
        _playbackSpeedView.hidden = _playbackSpeedViewHidden;
        self.navigationController.navigationBar.hidden = _controlsHidden;
        _trackSelectorContainer.hidden = YES;
        _equalizerView.hidden = YES;
        if (_sleepTimerContainer)
            _sleepTimerContainer.hidden = YES;
        _multiSelectionView.hidden = YES;

        _artistNameLabel.hidden = _audioOnly ? NO : _controlsHidden;
        _albumNameLabel.hidden =  _audioOnly ? NO : _controlsHidden;
        _trackNameLabel.hidden =  _audioOnly ? NO : _controlsHidden;
        _subheadingLable.hidden=_audioOnly?NO:_controlsHidden;
    };

    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;

    [[UIApplication sharedApplication] setStatusBarHidden:_viewAppeared ? _controlsHidden : NO withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

- (void)toggleControlsVisible:(UITapGestureRecognizer *)selfTap
{
    if (!_trackSelectorContainer.hidden) {
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:YES];
    }

    if (_controlsHidden && !_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_isTapSeeking)
        _numberOfTapSeek = 0;
    NSLog(@"%@",selfTap.view);
//    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
//    if (orientation==UIDeviceOrientationLandscapeRight||orientation==UIDeviceOrientationLandscapeLeft) {
        self.tVListChannel.hidden=!_controlsHidden;
//    }
    [self setControlsHidden:!_controlsHidden animated:YES];
}

- (void)updateActivityIndicatorForState:(VLCMediaPlayerState)state
{
    if (state == VLCMediaPlayerStatePlaying || state == VLCMediaPlayerStatePaused) {
        _previousPlayerStateWasPaused = state == VLCMediaPlayerStatePaused;
    }
    BOOL shouldAnimate = state == VLCMediaPlayerStateBuffering && !_previousPlayerStateWasPaused;
    if (self.activityIndicator.isAnimating != shouldAnimate) {
        self.activityIndicator.alpha = shouldAnimate ? 1.0 : 0.0;
        shouldAnimate ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
    }
}

- (void)_resetIdleTimer
{
    if (!_idleTimer)
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:4.
                                                      target:self
                                                    selector:@selector(idleTimerExceeded)
                                                    userInfo:nil
                                                     repeats:NO];
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < 4.)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.]];
    }
}

- (NSString *)_stringInTimeFormatFrom:(int)duration
{
    if (duration < 60) {
        return [NSString stringWithFormat:@"%is", duration];
    } else {
        return [NSString stringWithFormat:@"%im%is", duration / 60, duration % 60];
    }
}

- (void)_seekFromTap
{
    NSMutableString *hudString = [NSMutableString string];

    int seekDuration = (int)_numberOfTapSeek * SHORT_JUMP_DURATION;

    if (seekDuration > 0) {
        [_vpc jumpForward:SHORT_JUMP_DURATION];
        [hudString appendString:@"⇒ "];
        _previousJumpState = rqdMediaMovieJumpStateForward;
    } else {
        [_vpc jumpBackward:SHORT_JUMP_DURATION];
        [hudString appendString:@"⇐ "];
        _previousJumpState = rqdMediaMovieJumpStateBackward;
    }
    [hudString appendString: [self _stringInTimeFormatFrom:abs(seekDuration)]];
    [self.statusLabel showStatusMessage:[NSString stringWithString:hudString]];
    if (_controlsHidden)
        [self setControlsHidden:NO animated:NO];
}

- (void)idleTimerExceeded
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(idleTimerExceeded) withObject:nil waitUntilDone:NO];
        return;
    }

    _idleTimer = nil;
    if (!_controlsHidden)
        [self toggleControlsVisible:nil];

    if (_isTapSeeking) {
        _isTapSeeking = NO;
        _numberOfTapSeek = 0;
    }

    if (!_videoFiltersHidden)
        _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (!_playbackSpeedViewHidden)
        _playbackSpeedViewHidden = YES;

    if (self.scrubIndicatorView.hidden == NO)
        self.scrubIndicatorView.hidden = YES;
}

- (UIResponder *)nextResponder
{
    [self _resetIdleTimer];
    return [super nextResponder];
}

- (rqdMediaDeviceMotion *)deviceMotion
{
    if (!_deviceMotion) {
        _deviceMotion = [rqdMediaDeviceMotion new];
        _deviceMotion.delegate = self;
    }
    return _deviceMotion;
}

- (void)setupForMediaProjection
{
    BOOL mediaHasProjection = [_vpc currentMediaIs360Video];
    _fov = mediaHasProjection ? DEFAULT_FOV : 0.f;

    [_swipeRecognizerUp setEnabled:!mediaHasProjection];
    [_swipeRecognizerDown setEnabled:!mediaHasProjection];
    [_swipeRecognizerLeft setEnabled:!mediaHasProjection];
    [_swipeRecognizerRight setEnabled:!mediaHasProjection];

    if (mediaHasProjection) {
        [self.deviceMotion startDeviceMotion];
    }
}

- (void)applyYaw:(CGFloat)diffYaw pitch:(CGFloat)diffPitch;
{
    //Add and limit new pitch and yaw
    self.deviceMotion.yaw += diffYaw;
    self.deviceMotion.pitch += diffPitch;

    [_vpc updateViewpoint:self.deviceMotion.yaw pitch:self.deviceMotion.pitch roll:0 fov:_fov absolute:YES];
}

- (void)deviceMotionHasAttitudeWithDeviceMotion:(rqdMediaDeviceMotion *)deviceMotion pitch:(double)pitch yaw:(double)yaw
{
    if (_panRecognizer.state != UIGestureRecognizerStateChanged || UIGestureRecognizerStateBegan) {
        [self applyYaw:yaw pitch:pitch];
    }
}
#pragma mark - controls

- (IBAction)closePlayback:(id)sender
{
    _vpc.currentPlayChannel=-1;
    _vpc.channels=@[];
    _vpc.dvrItem=nil;
    hideViewList=NO;
//    self.tVListChannel=nil;
    _playbackWillClose = YES;
    [_vpc stopPlayback];
}

- (IBAction)minimizePlayback:(id)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(closeFullscreenPlayback) to:nil from:self forEvent:nil];
}

- (IBAction)positionSliderAction:(UISlider *)sender
{
    /* we need to limit the number of events sent by the slider, since otherwise, the user
     * wouldn't see the I-frames when seeking on current mobile devices. This isn't a problem
     * within the Simulator, but especially on older ARMv7 devices, it's clearly noticeable. */
    [self performSelector:@selector(_setPositionForReal) withObject:nil afterDelay:0.3];
    if (_mediaDuration > 0) {
        VLCTime *newPosition = [VLCTime timeWithInt:(int)(sender.value * _mediaDuration)];
        [self.timeNavigationTitleView.timeDisplayButton setTitle:newPosition.stringValue forState:UIControlStateNormal];
        [self.timeNavigationTitleView setNeedsLayout];
        self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"PLAYBACK_POSITION", nil), newPosition.stringValue];
        _positionSet = NO;
    }
    [self _resetIdleTimer];
}

- (void)_setPositionForReal
{
    if (!_positionSet) {
        [_vpc setPlaybackPosition:self.timeNavigationTitleView.positionSlider.value];
        [_vpc setNeedsMetadataUpdate];
        _positionSet = YES;
    }
}

- (IBAction)positionSliderTouchDown:(id)sender
{
    [self _updateScrubLabel];
    self.scrubIndicatorView.hidden = NO;
    _isScrubbing = YES;
}

- (IBAction)positionSliderTouchUp:(id)sender
{
    self.scrubIndicatorView.hidden = YES;
    _isScrubbing = NO;
}

- (void)_updateScrubLabel
{
    float speed = self.timeNavigationTitleView.positionSlider.scrubbingSpeed;
    if (speed == 1.)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HIGH", nil);
    else if (speed == .5)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_HALF", nil);
    else if (speed == .25)
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_QUARTER", nil);
    else
        self.currentScrubSpeedLabel.text = NSLocalizedString(@"PLAYBACK_SCRUB_FINE", nil);

    [self _resetIdleTimer];
}

- (IBAction)positionSliderDrag:(id)sender
{
    [self _updateScrubLabel];
}

- (void)volumeSliderAction:(id)sender
{
    [self _resetIdleTimer];
}

- (void)updateTimeDisplayButton
{
    UIButton *timeDisplayButton = self.timeNavigationTitleView.timeDisplayButton;
    if (_displayRemainingTime)
        [timeDisplayButton setTitle:[[_vpc remainingTime] stringValue] forState:UIControlStateNormal];
    else
        [timeDisplayButton setTitle:[[_vpc playedTime] stringValue] forState:UIControlStateNormal];
    [self.timeNavigationTitleView setNeedsLayout];
}

- (void)updateSleepTimerButton
{
    NSMutableString *title = [NSMutableString stringWithString:NSLocalizedString(@"BUTTON_SLEEP_TIMER", nil)];
    if (_vpc.sleepTimer != nil && _vpc.sleepTimer.valid) {
        int remainSeconds = (int)[_vpc.sleepTimer.fireDate timeIntervalSinceNow];
        int hour = remainSeconds / 3600;
        int minute = (remainSeconds - hour * 3600) / 60;
        int second = remainSeconds % 60;
        [title appendFormat:@"  %02d:%02d:%02d", hour, minute, second];
    } else {
        [_sleepCountDownTimer invalidate];
    }

    [_sleepTimerButton setTitle:title forState:UIControlStateNormal];
}

-(TVListChannel *)tVListChannel{
    if (!_tVListChannel) {
        _tVListChannel=[[TVListChannel alloc]init];
//        _tVListChannel.hidden=YES;
    }
    _tVListChannel.ClockChannel = ^(TVHChannel *channel, NSInteger selectIndex) {
        [_vpc stopPlayNext:selectIndex];
    };
    _tVListChannel.IsRoll = ^(BOOL isRoll) {
        _controlsHidden=isRoll;
    };
    return _tVListChannel;
}

-(void)layer{
    if (!hideViewList) {
        self.recordingutton.hidden=NO;
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        [self.tVListChannel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(64);
            if (orientation==UIDeviceOrientationLandscapeRight||orientation==UIDeviceOrientationLandscapeLeft) {
                make.bottom.mas_equalTo(-56);
            }else{
                make.bottom.mas_equalTo(-105);
            }
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(200);
            
        }];
    }else{
        self.recordingutton.hidden=YES;
        [self.tVListChannel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            
                make.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(0);
        }];
    }
}

#pragma mark - playback controller delegation

- (void)playbackPositionUpdated:(rqdMediaPlaybackController *)controller
{
    
    // FIXME: hard coded state since the state in mediaPlayer is incorrectly still buffering
    [self updateActivityIndicatorForState:VLCMediaPlayerStatePlaying];

    if (!_isScrubbing) {
        self.timeNavigationTitleView.positionSlider.value = [controller playbackPosition];
    }

    [self updateTimeDisplayButton];
}

- (void)prepareForMediaPlayback:(rqdMediaPlaybackController *)controller
{
    self.tVListChannel.currentPlayChannel=controller.currentPlayChannel;
    NSLog(@"%ld",(long)controller.currentPlayChannel);
    self.mediaList=controller.mediaList;
    self.tVListChannel.channels=controller.channels;
    self.trackNameLabel.text = self.artistNameLabel.text = self.albumNameLabel.text =self.subheadingLable.text= @"";
    self.timeNavigationTitleView.positionSlider.value = 0.;
    [self.timeNavigationTitleView.timeDisplayButton setTitle:@"" forState:UIControlStateNormal];
    
 self.timeNavigationTitleView.timeDisplayButton.accessibilityLabel = @"";
    [_equalizerView reloadData];

    double playbackRate = controller.playbackRate;
    self.playbackSpeedSlider.value = log2(playbackRate);
    self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", playbackRate];

    float audioDelay = controller.audioDelay;
    self.audioDelaySlider.value = audioDelay;
    self.audioDelayIndicator.text = [NSString stringWithFormat:@"%d ms", (int) audioDelay];

    float subtitleDelay = controller.subtitleDelay;
    self.spuDelaySlider.value = subtitleDelay;
    self.spuDelayIndicator.text = [NSString stringWithFormat:@"%d ms", (int) subtitleDelay];

    [self _resetIdleTimer];
}

- (void)playbackDidStop:(NSNotification *)notification
{
    [self minimizePlayback:nil];
}

- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)currentState
                      isPlaying:(BOOL)isPlaying
currentMediaHasTrackToChooseFrom:(BOOL)currentMediaHasTrackToChooseFrom
        currentMediaHasChapters:(BOOL)currentMediaHasChapters
          forPlaybackController:(rqdMediaPlaybackController *)controller
{
    [self updateActivityIndicatorForState:currentState];

    if (currentState == VLCMediaPlayerStateBuffering)
        _mediaDuration = controller.mediaDuration;

    if (currentState == VLCMediaPlayerStateError)
        [self.statusLabel showStatusMessage:NSLocalizedString(@"PLAYBACK_FAILED", nil)];

    [_controllerPanel updateButtons];

    _multiSelectionView.mediaHasChapters = currentMediaHasChapters;
}

- (void)showStatusMessage:(NSString *)statusMessage forPlaybackController:(rqdMediaPlaybackController *)controller
{
    [self.statusLabel showStatusMessage:statusMessage];
}

- (void)hideShowAspectratioButton:(BOOL)hide
{
    [UIView animateWithDuration:.3
                     animations:^{
                         self.widthConstraint.constant = hide ? 0 : 30;
                         self.timeNavigationTitleView.aspectRatioButton.hidden = hide;
                     }];
}

- (void)displayMetadataForPlaybackController:(rqdMediaPlaybackController *)controller metadata:(VLCMetaData *)metadata
{
    if (!_viewAppeared)
        return;
    self.recordingutton.hidden=YES;
    if (controller.dvrItem) {
        hideViewList=YES;
        self.trackNameLabel.text = controller.dvrItem.title;
    }else{
        hideViewList=NO;
        if (self.tVListChannel.channels.count<=0) {
            NSLog(@"%@",[controller.mediaList valueForKey:@"mediaObjects"]);
            self.tVListChannel.channels=[controller.mediaList valueForKey:@"mediaObjects"];
            self.trackNameLabel.text = metadata.title;
        }else{
            if (self.tVListChannel.currentPlayChannel>=self.tVListChannel.channels.count) {
                return;
            }
            id TvHchannel=self.tVListChannel.channels[self.tVListChannel.currentPlayChannel];
            
            self.subheadingLable.text=@"";
            if ([TvHchannel isKindOfClass:[TVHChannel class]]) {
                self.recordingutton.hidden=NO;
                TVHChannel *channel=(TVHChannel *)TvHchannel;
                TVHEpg *currentEPG = [channel nextPrograms:3][0];
                // 日期格式化类
                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                // 设置日期格式 为了转换成功
                format.dateFormat = @"HH:mm";
                NSString *startTime = [format stringFromDate:currentEPG.start];
                NSString *endTime = [format stringFromDate:currentEPG.end];
                if (startTime.length>0) {
                    self.subheadingLable.text=[NSString stringWithFormat:@"%@-%@ %@",startTime.length>0?startTime:@"",endTime.length>0?endTime:@"",currentEPG.title.length>0?currentEPG.title:@""];
                    self.trackNameLabel.text = channel.name;
                }else{
                    self.trackNameLabel.text = channel.name;
                    
                }
                
            }else{
                
                self.trackNameLabel.text = metadata.title;
                
            }
        }
    }
    
    
    
    self.artworkImageView.image = metadata.artworkImage;
    if (!metadata.artworkImage) {
        self.artistNameLabel.text = metadata.artist;
        self.albumNameLabel.text = metadata.albumName;
    } else
        self.artistNameLabel.text = self.albumNameLabel.text = nil;

    [self hideShowAspectratioButton:metadata.isAudioOnly];
    [_controllerPanel updateButtons];
    
    _audioOnly = metadata.isAudioOnly;
}

- (IBAction)playPause
{
    [_vpc playPause];
}

- (IBAction)forward:(id)sender
{
    [_vpc next];
}

- (IBAction)backward:(id)sender
{
    [_vpc previous];
}

- (IBAction)switchTrack:(id)sender
{
    if (_trackSelectorContainer.hidden == YES || _trackSelectorContainer.switchingTracksNotChapters == NO) {
        _trackSelectorContainer.switchingTracksNotChapters = YES;

        _trackSelectorContainer.hidden = NO;
        _trackSelectorContainer.alpha = 1.;

        [_trackSelectorContainer updateView];

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;

        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
            [recognizer setEnabled:NO];
        [_tapOnVideoRecognizer setEnabled:YES];

    } else {
        _trackSelectorContainer.hidden = YES;
        _trackSelectorContainer.switchingTracksNotChapters = NO;
    }
}

- (IBAction)toggleTimeDisplay:(id)sender
{
    _displayRemainingTime = !_displayRemainingTime;
    [self updateTimeDisplayButton];

    [self _resetIdleTimer];
}

- (IBAction)sleepTimer:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
        }
    }

    self.videoFilterView.hidden = _videoFiltersHidden = YES;
    _sleepTimerContainer.alpha = 1.;
    _sleepTimerContainer.hidden = NO;
}

- (IBAction)sleepTimerCancel:(id)sender
{
    NSTimer *sleepTimer = [_vpc sleepTimer];

    if (sleepTimer) {
        [sleepTimer invalidate];
        sleepTimer = nil;
    }
    [self.statusLabel showStatusMessage:NSLocalizedString(@"SLEEP_TIMER_UPDATED", nil)];
    [self setControlsHidden:YES animated:YES];
}

- (IBAction)sleepTimerAction:(id)sender
{
    [_vpc scheduleSleepTimerWithInterval:_sleepTimeDatePicker.countDownDuration];

    if (_sleepCountDownTimer == nil || _sleepCountDownTimer.valid == NO) {
        _sleepCountDownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                   target:self
                                                                 selector:@selector(updateSleepTimerButton)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
    [self.statusLabel showStatusMessage:NSLocalizedString(@"SLEEP_TIMER_UPDATED", nil)];
    [self setControlsHidden:YES animated:YES];
}

- (void)moreActions:(UIButton *)sender
{
    if (_multiSelectionView.hidden == NO) {
        [UIView animateWithDuration:.3
                         animations:^{
                             _multiSelectionView.hidden = YES;
                         }
                         completion:^(BOOL finished){
                         }];
        return;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            _multiSelectionView.showsEqualizer = YES;
        } else {
            _multiSelectionView.showsEqualizer = NO;
        }
    }

    CGRect workFrame = _multiSelectionView.frame;
    workFrame.size = [_multiSelectionView proposedDisplaySize];
    workFrame.origin.x = CGRectGetMaxX(sender.frame) - workFrame.size.width;

    _multiSelectionView.alpha = 1.0f;

    /* animate */
    _multiSelectionView.frame = CGRectMake(workFrame.origin.x, workFrame.origin.y + workFrame.size.height, workFrame.size.width, 0.);
    [UIView animateWithDuration:.3
                     animations:^{
                         _multiSelectionView.frame = workFrame;
                         _multiSelectionView.hidden = NO;
                     }
                     completion:^(BOOL finished){
                     }];
    [self _resetIdleTimer];
}

#pragma mark - multi-select delegation

- (void)toggleUILock
{
    _interfaceIsLocked = !_interfaceIsLocked;
    if (_interfaceIsLocked) {
        _lockedOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    }

    NSArray *items = [self itemsForInterfaceLock];

    for (NSObject *item in items) {
        if ([item isKindOfClass:[UIControl class]]) {
            UIControl *control = (UIControl *)item;
            control.enabled = !_interfaceIsLocked;
        } else if ([item isKindOfClass:[UIGestureRecognizer class]]){
            UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)item;
            gestureRecognizer.enabled = !_interfaceIsLocked;
        } else if ([item isKindOfClass:[rqdMediaVolumeView class]]) {
            //The MPVolumeview doesn't adjust it's UI when disabled so we need to set the alpha by hand
            rqdMediaVolumeView *view = (rqdMediaVolumeView *)item;
            view.userInteractionEnabled = !_interfaceIsLocked;
            view.alpha = _interfaceIsLocked ? 0.5 : 1;
        } else {
            NSAssert(NO, @"class not handled");
        }
    }
    _multiSelectionView.displayLock = _interfaceIsLocked;
}

- (void)toggleEqualizer
{
    if (_equalizerView.hidden) {
        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (!_controlsHidden) {
                self.controllerPanel.hidden = _controlsHidden = YES;
                self.navigationController.navigationBar.hidden = YES;
            }
        }

        _trackSelectorContainer.hidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;
        _equalizerView.alpha = 1.;
        _equalizerView.hidden = NO;
    } else
        _equalizerView.hidden = YES;
}

- (void)toggleChapterAndTitleSelector
{
    if (_trackSelectorContainer.hidden == YES || _trackSelectorContainer.switchingTracksNotChapters == YES) {
        _trackSelectorContainer.switchingTracksNotChapters = NO;
        [_trackSelectorContainer updateView];

        _trackSelectorContainer.hidden = NO;
        _trackSelectorContainer.alpha = 1.;

        if (_equalizerView.hidden == NO)
            _equalizerView.hidden = YES;

        if (!_playbackSpeedViewHidden)
            self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (!_controlsHidden) {
                self.controllerPanel.hidden = _controlsHidden = YES;
            }
        }

        _sleepTimerContainer.hidden = YES;

        self.videoFilterView.hidden = _videoFiltersHidden = YES;
    } else {
        _trackSelectorContainer.hidden = YES;
    }
}

- (void)toggleRepeatMode
{
    [[rqdMediaPlaybackController sharedInstance] toggleRepeatMode];
    _multiSelectionView.repeatMode = [rqdMediaPlaybackController sharedInstance].repeatMode;
}

- (void)toggleShuffleMode
{
    _vpc.shuffleMode = !_vpc.isShuffleMode;
    _multiSelectionView.shuffleMode = _vpc.isShuffleMode;
}

- (void)hideMenu
{
    [UIView animateWithDuration:.2
                     animations:^{
                         _multiSelectionView.hidden = YES;
                     }
                     completion:^(BOOL finished){
                     }];
    [self _resetIdleTimer];
}

#pragma mark - multi-touch gestures

- (void)togglePlayPause
{
    if (!_playPauseGestureEnabled)
        return;

    if (_vpc.isPlaying) {
        [_vpc pause];
        [self setControlsHidden:NO animated:_controlsHidden];
    } else {
        [_vpc play];
    }
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

- (rqdMediaPanType)detectPanTypeForPan:(UIPanGestureRecognizer*)panRecognizer
{
    NSString *deviceType = [[UIDevice currentDevice] model];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CGFloat windowWidth = CGRectGetWidth(window.bounds);
    CGPoint location = [panRecognizer locationInView:window];

    rqdMediaPanType panType = rqdMediaPanTypeVolume; // default or right side of the screen
    if (location.x < windowWidth / 2)
        panType = rqdMediaPanTypeBrightness;

    // only check for seeking gesture if on iPad , will overwrite last statements if true
    if ([deviceType isEqualToString:@"iPad"] && location.y < 110) {
        panType = rqdMediaPanTypeSeek;
    }

    if ([_vpc currentMediaIs360Video]) {
        panType = rqdMediaPanTypeProjection;
    }

    return panType;
}

- (void)panRecognized:(UIPanGestureRecognizer*)panRecognizer
{
    CGFloat panDirectionX = [panRecognizer velocityInView:self.view].x;
    CGFloat panDirectionY = [panRecognizer velocityInView:self.view].y;
    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        _currentPanType = [self detectPanTypeForPan:panRecognizer];
        if ([_vpc currentMediaIs360Video]) {
            _saveLocation =  [panRecognizer locationInView:self.view];
            [_deviceMotion stopDeviceMotion];
        }
    }
    
    switch (_currentPanType) {
        case rqdMediaPanTypeSeek: {
            if (!_seekGestureEnabled)
                return;
            double timeRemainingDouble = (-[_vpc remainingTime].intValue*0.001);
            int timeRemaining = timeRemainingDouble;

            if (panDirectionX > 0) {
                if (timeRemaining > 2 ) // to not go outside duration , video will stop
                    [_vpc jumpForward:1];
            } else
                [_vpc jumpBackward:1];

            break;
        case rqdMediaPanTypeVolume:

            if (!_volumeGestureEnabled)
                return;
            MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
            // there is no replacement for .volume which we want to use since Apple's susggestion is to not use their overlays
            // but switch to the volume slider exclusively. meh.
            if (panDirectionY > 0)
                musicPlayer.volume -= 0.01;
            else
                musicPlayer.volume += 0.01;
#pragma clang diagnostic pop
        } break;
        case rqdMediaPanTypeBrightness: {
            if (!_brightnessGestureEnabled)
                return;
            CGFloat brightness = [UIScreen mainScreen].brightness;

            if (panDirectionY > 0)
                brightness = brightness - 0.01;
            else
                brightness = brightness + 0.01;

            // Sanity check since -[UIScreen brightness] does not go by 0.01 steps
            if (brightness > 1.0)
                brightness = 1.0;
            else if (brightness < 0.0)
                brightness = 0.0;

            NSAssert(brightness >= 0 && brightness <= 1, @"Brightness must be within 0 and 1 (it is %f)", brightness);

            [[UIScreen mainScreen] setBrightness:brightness];

            NSString *brightnessHUD = [NSString stringWithFormat:@"%@: %@ %%", NSLocalizedString(@"VFILTER_BRIGHTNESS", nil), [[[NSString stringWithFormat:@"%f",(brightness*100)] componentsSeparatedByString:@"."] objectAtIndex:0]];
            [self.statusLabel showStatusMessage:brightnessHUD];
        } break;
        case rqdMediaPanTypeProjection: {
            [self updateProjectionWithPanRecognizer:panRecognizer];
        } break;
        case rqdMediaPanTypeNone: {
        } break;
    }

    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        _currentPanType = rqdMediaPanTypeNone;
        if ([_vpc currentMediaIs360Video]) {
            [_deviceMotion startDeviceMotion];
        }
    }
}

- (void)updateProjectionWithPanRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint newLocationInView = [panGestureRecognizer locationInView:self.view];
    
    CGFloat diffX = newLocationInView.x - _saveLocation.x;
    CGFloat diffY = newLocationInView.y - _saveLocation.y;
    _saveLocation = newLocationInView;

    //screenSizePixel width is used twice to get a constant speed on the movement.
    CGFloat diffYaw = _fov * -diffX / _screenPixelSize.width;
    CGFloat diffPitch = _fov * -diffY / _screenPixelSize.width;

    [self applyYaw:diffYaw pitch:diffPitch];
}

- (void)swipeRecognized:(UISwipeGestureRecognizer*)swipeRecognizer
{
    if (!_seekGestureEnabled)
        return;

    NSString * hudString = @" ";

    int swipeForwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : FORWARD_SWIPE_DURATION;
    int swipeBackwardDuration = (_variableJumpDurationEnabled) ? ((int)(_mediaDuration*0.001*0.05)) : BACKWARD_SWIPE_DURATION;

    if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        double timeRemainingDouble = (-[_vpc remainingTime].intValue*0.001);
        int timeRemaining = timeRemainingDouble;

        if (swipeForwardDuration < timeRemaining) {
            if (swipeForwardDuration < 1)
                swipeForwardDuration = 1;
            [_vpc jumpForward:swipeForwardDuration];
            hudString = [NSString stringWithFormat:@"⇒ %is", swipeForwardDuration];
        } else {
            [_vpc jumpForward:(timeRemaining - 5)];
            hudString = [NSString stringWithFormat:@"⇒ %is",(timeRemaining - 5)];
        }
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [_vpc jumpBackward:swipeBackwardDuration];
        hudString = [NSString stringWithFormat:@"⇐ %is",swipeBackwardDuration];
    }else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        [self backward:self];
    }
    else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self forward:self];
    }

    if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {

        [self.statusLabel showStatusMessage:hudString];
    }
}

- (void)tapToSeekRecognized:(UITapGestureRecognizer *)tapRecognizer
{
    if (!_seekGestureEnabled)
        return;

    CGFloat screenHalf;
    CGFloat tmpPosition;
    CGSize size = self.view.frame.size;
    CGPoint tapPosition = [tapRecognizer locationInView:self.view];

    screenHalf = size.width / 2;
    tmpPosition = tapPosition.x;

    //Handling seek reset if tap orientation changes.
    if (tmpPosition < screenHalf) {
        _numberOfTapSeek = _previousJumpState == rqdMediaMovieJumpStateForward ? -1 : _numberOfTapSeek - 1;
    } else {
        _numberOfTapSeek = _previousJumpState == rqdMediaMovieJumpStateBackward ? 1 : _numberOfTapSeek + 1;
    }

    _isTapSeeking = YES;
    [self _seekFromTap];
}

- (void)equalizerViewReceivedUserInput
{
    [self _resetIdleTimer];
}

#pragma mark - Video Filter UI

- (IBAction)videoFilterToggle:(id)sender
{
    if (!_playbackSpeedViewHidden)
        self.playbackSpeedView.hidden = _playbackSpeedViewHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!_controlsHidden) {
            self.controllerPanel.hidden = _controlsHidden = YES;
        }
    }

    self.videoFilterView.hidden = !_videoFiltersHidden;
    _videoFiltersHidden = self.videoFilterView.hidden;
}

- (IBAction)videoFilterSliderAction:(id)sender
{
    if (sender == self.hueSlider)
        _vpc.hue = self.hueSlider.value;
    else if (sender == self.contrastSlider)
        _vpc.contrast = self.contrastSlider.value;
    else if (sender == self.brightnessSlider)
        _vpc.brightness = self.brightnessSlider.value;
    else if (sender == self.saturationSlider)
        _vpc.saturation = self.saturationSlider.value;
    else if (sender == self.gammaSlider)
        _vpc.gamma = self.gammaSlider.value;
    else if (sender == self.resetVideoFilterButton) {
        [self resetVideoFiltersSliders];
        [_vpc resetFilters];
    } else
        APLog(@"unknown sender for videoFilterSliderAction");
    [self _resetIdleTimer];
}

- (void)appBecameActive:(NSNotification *)aNotification
{
    rqdMediaPlayerDisplayController *pdc = [rqdMediaPlayerDisplayController sharedInstance];
    if (pdc.displayMode == rqdMediaPlayerDisplayControllerDisplayModeFullscreen) {
        [_vpc recoverDisplayedMetadata];
        if (_vpc.videoOutputView != self.movieView) {
            _vpc.videoOutputView = self.movieView;
        }
    }
}

#pragma mark - playback view
- (IBAction)playbackSliderAction:(UISlider *)sender
{
    if (sender == _playbackSpeedSlider) {
        double speed = exp2(sender.value);
        _vpc.playbackRate = speed;
        self.playbackSpeedIndicator.text = [NSString stringWithFormat:@"%.2fx", speed];
    } else if (sender == _audioDelaySlider) {
        int delay = ((int) round(sender.value / 50.)) * 50;
        _vpc.audioDelay = delay;
        [sender setValue:delay animated:NO];
        _audioDelayIndicator.text = [NSString stringWithFormat:@"%d ms", delay];
    } else if (sender == _spuDelaySlider) {
        int delay = (int) (round(sender.value / 50.)) * 50;
        _vpc.subtitleDelay = delay;
        [sender setValue:delay animated:NO];
        _spuDelayIndicator.text = [NSString stringWithFormat:@"%d ms", delay];
    }

    [self _resetIdleTimer];
}

- (IBAction)videoDimensionAction:(id)sender
{
    if (sender == self.timeNavigationTitleView.aspectRatioButton) {
        [[rqdMediaPlaybackController sharedInstance] switchAspectRatio];
    }
}

- (IBAction)showPlaybackSpeedView {
    if (!_videoFiltersHidden)
        self.videoFilterView.hidden = _videoFiltersHidden = YES;

    if (_equalizerView.hidden == NO)
        _equalizerView.hidden = YES;

    self.playbackSpeedView.hidden = !_playbackSpeedViewHidden;
    _playbackSpeedViewHidden = self.playbackSpeedView.hidden;
    [self _resetIdleTimer];
}

#pragma mark - autorotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    BOOL orientationIslocked = _interfaceIsLocked || [_vpc currentMediaIs360Video];
    UIInterfaceOrientationMask maskFromOrientation = 1 << _lockedOrientation;
    return orientationIslocked ? maskFromOrientation :  UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           || toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (_vpc.isPlaying && _controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (self.artworkImageView.image){
                self.subheadingLable.hidden=YES;
                self.trackNameLabel.hidden = YES;
            }
                if (!_equalizerView.hidden)
                    _equalizerView.hidden = YES;
        } completion:nil];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    if (_vpc.isPlaying && _controlsHidden)
        [self setControlsHidden:NO animated:YES];
}

#pragma mark - External Display

- (void)showOnDisplay:(UIView *)view
{
    // if we don't have a renderer we're mirroring and don't want to show the dialog
    BOOL displayExternally = view != _movieView;
    [_playingExternalView shouldDisplay:displayExternally movieView:_movieView];
    [_playingExternalView updateUIWithRendererItem:_vpc.renderer];
    _artworkImageView.hidden = displayExternally;
    if (!displayExternally && _movieView.superview != self.view) {
        [self.view addSubview:_movieView];
        [self.view sendSubviewToBack:_movieView];
        _movieView.frame = self.view.frame;
    }
}

- (void)handleExternalScreenDidConnect:(NSNotification *)notification
{
    [self showOnDisplay:_playingExternalView.displayView];
}

- (void)handleExternalScreenDidDisconnect:(NSNotification *)notification
{
    [self showOnDisplay:_movieView];
}

#pragma mark - Renderers

- (void)setupRendererDiscovererManager
{
    // Create a renderer button for rqdMediaMovieViewController
    _rendererButton = [VLCRendererDiscovererManager.sharedInstance setupRendererButton];
    [VLCRendererDiscovererManager.sharedInstance addSelectionHandler:^(VLCRendererItem * item) {
        if (item) {
            [self showOnDisplay:_playingExternalView.displayView];
        } else {
            [self removedCurrentRendererItem:_vpc.renderer];
        }
    }];
}

#pragma mark - VLCRendererDiscovererManagerDelegate

- (void)removedCurrentRendererItem:(VLCRendererItem *)item
{
    [self showOnDisplay:_movieView];
}
@end
