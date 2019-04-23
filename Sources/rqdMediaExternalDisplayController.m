/*****************************************************************************
 * rqdMediaExternalDisplayController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaExternalDisplayController.h"

@interface rqdMediaExternalDisplayController ()

@end

@implementation rqdMediaExternalDisplayController

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return ~UIInterfaceOrientationMaskAll;
}

@end
