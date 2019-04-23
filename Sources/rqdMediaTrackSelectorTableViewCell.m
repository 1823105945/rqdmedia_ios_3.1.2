/*****************************************************************************
 * rqdMediaTrackSelectorTableViewCell.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaTrackSelectorTableViewCell.h"

@implementation rqdMediaTrackSelectorTableViewCell

- (void)setShowsCurrentTrack
{
    self.backgroundColor = [UIColor rqdMediaLightTextColor];
    self.textLabel.textColor = [UIColor rqdMediaDarkBackgroundColor];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [UIColor rqdMediaLightTextColor];
}
@end
