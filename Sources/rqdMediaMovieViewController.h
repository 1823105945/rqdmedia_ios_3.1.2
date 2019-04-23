/*****************************************************************************
 * rqdMediaMovieViewController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <MediaPlayer/MediaPlayer.h>
#import "rqdMediaFrostedGlasView.h"
#import "VLCPlaybackController.h"

@class OBSlider;
@class rqdMediaStatusLabel;
@class rqdMediaHorizontalSwipeGestureRecognizer;
@class rqdMediaVerticalSwipeGestureRecognizer;
@class VLCTimeNavigationTitleView;
@class rqdMediaMovieViewControlPanelView;

typedef NS_ENUM(NSInteger, rqdMediaMovieJumpState) {
    rqdMediaMovieJumpStateDefault,
    rqdMediaMovieJumpStateForward,
    rqdMediaMovieJumpStateBackward
};

@interface rqdMediaMovieViewController : UIViewController <UIActionSheetDelegate, rqdMediaPlaybackControllerDelegate>
@property (nonatomic, strong) IBOutlet UIView *movieView;
@property (nonatomic, strong) IBOutlet VLCTimeNavigationTitleView *timeNavigationTitleView;
@property (nonatomic, strong) IBOutlet UIButton *sleepTimerButton;
@property (nonatomic, strong) IBOutlet rqdMediaStatusLabel *statusLabel;

@property (nonatomic, strong) IBOutlet rqdMediaFrostedGlasView *videoFilterView;
@property (nonatomic, strong) IBOutlet UILabel *hueLabel;
@property (nonatomic, strong) IBOutlet UISlider *hueSlider;
@property (nonatomic, strong) IBOutlet UILabel *contrastLabel;
@property (nonatomic, strong) IBOutlet UISlider *contrastSlider;
@property (nonatomic, strong) IBOutlet UILabel *brightnessLabel;
@property (nonatomic, strong) IBOutlet UISlider *brightnessSlider;
@property (nonatomic, strong) IBOutlet UILabel *saturationLabel;
@property (nonatomic, strong) IBOutlet UISlider *saturationSlider;
@property (nonatomic, strong) IBOutlet UILabel *gammaLabel;
@property (nonatomic, strong) IBOutlet UISlider *gammaSlider;
@property (nonatomic, strong) IBOutlet UIButton *resetVideoFilterButton;

@property (nonatomic, strong) IBOutlet rqdMediaFrostedGlasView *playbackSpeedView;
@property (nonatomic, strong) IBOutlet UISlider *playbackSpeedSlider;
@property (nonatomic, strong) IBOutlet UILabel *playbackSpeedLabel;
@property (nonatomic, strong) IBOutlet UILabel *playbackSpeedIndicator;
@property (nonatomic, strong) IBOutlet UISlider *audioDelaySlider;
@property (nonatomic, strong) IBOutlet UILabel *audioDelayLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioDelayIndicator;
@property (nonatomic, strong) IBOutlet UISlider *spuDelaySlider;
@property (nonatomic, strong) IBOutlet UILabel *spuDelayLabel;
@property (nonatomic, strong) IBOutlet UILabel *spuDelayIndicator;

@property (nonatomic, strong) IBOutlet rqdMediaFrostedGlasView *scrubIndicatorView;
@property (nonatomic, strong) IBOutlet UILabel *currentScrubSpeedLabel;
@property (nonatomic, strong) IBOutlet UILabel *scrubHelpLabel;

@property (nonatomic, strong) IBOutlet UILabel *artistNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *albumNameLabel;
//标题
@property (nonatomic, strong) IBOutlet UILabel *trackNameLabel;
//副标题
@property (weak, nonatomic) IBOutlet UILabel *subheadingLable;

@property (nonatomic, strong) IBOutlet UIImageView *artworkImageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *widthConstraint;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)closePlayback:(id)sender;
- (IBAction)minimizePlayback:(id)sender;

- (IBAction)positionSliderAction:(id)sender;
- (IBAction)positionSliderTouchDown:(id)sender;
- (IBAction)positionSliderTouchUp:(id)sender;
- (IBAction)positionSliderDrag:(id)sender;
- (IBAction)toggleTimeDisplay:(id)sender;

- (IBAction)sleepTimer:(id)sender;

- (IBAction)videoFilterSliderAction:(id)sender;

- (IBAction)playbackSliderAction:(id)sender;
- (IBAction)videoDimensionAction:(id)sender;

- (void)toggleRepeatMode;
- (void)toggleShuffleMode;
- (void)toggleEqualizer;
- (void)toggleUILock;
- (void)toggleChapterAndTitleSelector;
- (void)hideMenu;

@end
