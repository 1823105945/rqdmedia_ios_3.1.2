/*****************************************************************************
 * rqdMediaBugreporter.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaBugreporter.h"

@implementation rqdMediaBugreporter

#pragma mark - Initialization

+ (rqdMediaBugreporter *)sharedInstance
{
    static dispatch_once_t onceToken;
    static rqdMediaBugreporter *_sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [rqdMediaBugreporter new];
    });

    return _sharedInstance;
}

#pragma mark -

- (void)handleBugreportRequest
{
    rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"BUG_REPORT_TITLE", nil)
                                                      message:NSLocalizedString(@"BUG_REPORT_MESSAGE", nil) delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:NSLocalizedString(@"BUG_REPORT_BUTTON", nil), nil];;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:@"https://trac.videolan.org/rqdmedia/newticket"];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
