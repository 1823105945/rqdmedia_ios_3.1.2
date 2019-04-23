/*****************************************************************************
 * rqdMediaPlayerDisplayController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class rqdMediaPlaybackController;

typedef NS_ENUM(NSUInteger, rqdMediaPlayerDisplayControllerDisplayMode) {
    rqdMediaPlayerDisplayControllerDisplayModeFullscreen,
    rqdMediaPlayerDisplayControllerDisplayModeMiniplayer,
};

@protocol rqdMediaMiniPlaybackViewInterface <NSObject>

@required;
@property (nonatomic) BOOL visible;

@end

@interface rqdMediaPlayerDisplayController : UIViewController

+ (rqdMediaPlayerDisplayController *)sharedInstance;

@property (nonatomic, strong) UIViewController *childViewController;

@property (nonatomic, assign) rqdMediaPlayerDisplayControllerDisplayMode displayMode;
@property (nonatomic, weak) rqdMediaPlaybackController *playbackController;

- (void)showFullscreenPlayback;
- (void)closeFullscreenPlayback;

- (void)pushPlaybackView;
- (void)dismissPlaybackView;

@end
