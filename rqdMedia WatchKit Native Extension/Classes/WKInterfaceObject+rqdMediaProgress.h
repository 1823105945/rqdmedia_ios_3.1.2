/*****************************************************************************
 * WKInterfaceObject+rqdMediaProgress.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>

@interface WKInterfaceObject (rqdMediaProgress)

- (void)rqdmedia_setProgress:(float)progress;
- (void)rqdmedia_setProgress:(float)progress hideForNoProgress:(BOOL)hide;

/* time and duration must be in the same timescale but we don't care about the scale*/
- (void)rqdmedia_setProgressFromPlaybackTime:(float)playbackTime duration:(float)duration hideForNoProgess:(BOOL)hide;
@end
