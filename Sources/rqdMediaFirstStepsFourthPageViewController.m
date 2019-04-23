/*****************************************************************************
 * rqdMediaFirstStepsFourthPageViewController
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaFirstStepsFourthPageViewController.h"

@interface rqdMediaFirstStepsFourthPageViewController ()

@end

@implementation rqdMediaFirstStepsFourthPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.uploadDescriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_CLOUD_UPLOAD_DETAILS", nil);
    self.accessDescriptionLabel.text = NSLocalizedString(@"FIRST_STEPS_CLOUD_ACCESS_DETAILS", nil);
}

- (NSString *)pageTitle
{
    return NSLocalizedString(@"FIRST_STEPS_CLOUDS", nil);
}

- (NSUInteger)page
{
    return 4;
}

@end
