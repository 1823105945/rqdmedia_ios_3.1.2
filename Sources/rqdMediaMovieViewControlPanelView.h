/*****************************************************************************
 * rqdMediaMovieViewControlPanelView.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan@tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import <UIKit/UIKit.h>
#import "rqdMediaVolumeView.h"
#import "rqdMediaFrostedGlasView.h"

@interface rqdMediaMovieViewControlPanelView : rqdMediaFrostedGlasView

@property (nonatomic, strong)  UIButton *playbackSpeedButton;
@property (nonatomic, strong)  UIButton *trackSwitcherButton;

@property (nonatomic, strong)  UIButton *bwdButton;
@property (nonatomic, strong)  UIButton *playPauseButton;
@property (nonatomic, strong)  UIButton *fwdButton;

@property (nonatomic, strong)  UIButton *videoFilterButton;
@property (nonatomic, strong)  UIButton *moreActionsButton;

@property (nonatomic, strong)  rqdMediaVolumeView *volumeView;

- (void)updateButtons;

@end
