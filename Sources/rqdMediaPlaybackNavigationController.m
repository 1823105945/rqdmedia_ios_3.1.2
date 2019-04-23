/*****************************************************************************
 * rqdMediaPlaybackNavigationController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlaybackNavigationController.h"

@implementation rqdMediaPlaybackNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
