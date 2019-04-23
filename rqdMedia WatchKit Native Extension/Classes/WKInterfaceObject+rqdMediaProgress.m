/*****************************************************************************
 * WKInterfaceObject+rqdMediaProgress.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "WKInterfaceObject+rqdMediaProgress.h"

@implementation WKInterfaceObject (rqdMediaProgress)

-(void)rqdmedia_setProgress:(float)progress
{
    float progressWidth = ceil(progress * CGRectGetWidth([WKInterfaceDevice currentDevice].screenBounds));
    self.width = progressWidth;
}

- (void)rqdmedia_setProgress:(float)progress hideForNoProgress:(BOOL)hideForNoProgress
{
    [self rqdmedia_setProgress:progress];
    BOOL noProgress = progress == 0.0;
    self.hidden = noProgress && hideForNoProgress;
}

- (void)rqdmedia_setProgressFromPlaybackTime:(float)playbackTime duration:(float)duration hideForNoProgess:(BOOL)hideForNoProgress
{
    float playbackProgress = 0.0;
    if (playbackTime > 0.0 && duration > 0.0) {
        playbackProgress = playbackTime / duration;
    }
    [self rqdmedia_setProgress:playbackProgress hideForNoProgress:hideForNoProgress];
}

@end
