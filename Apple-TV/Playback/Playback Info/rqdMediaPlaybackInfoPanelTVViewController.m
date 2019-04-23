/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlaybackInfoPanelTVViewController.h"

@interface rqdMediaPlaybackInfoPanelTVViewController ()

@end

@implementation rqdMediaPlaybackInfoPanelTVViewController

static inline void sharedSetup(rqdMediaPlaybackInfoPanelTVViewController *self)
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sharedSetup(self);
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    sharedSetup(self);
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(CGRectGetWidth(self.view.bounds), 100);
}

// private API to prevent tab bar from hiding
- (BOOL)_tvTabBarShouldAutohide
{
    return NO;
}

+ (BOOL)shouldBeVisibleForPlaybackController:(rqdMediaPlaybackController *)vpc
{
    return YES;
}

@end
