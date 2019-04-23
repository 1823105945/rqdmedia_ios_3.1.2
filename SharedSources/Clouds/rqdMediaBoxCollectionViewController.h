/*****************************************************************************
 * rqdMediaBoxCollectionViewController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaCloudStorageTVViewController.h"

@interface rqdMediaBoxCollectionViewController : rqdMediaCloudStorageTVViewController

- (instancetype)initWithPath:(NSString *)path;

@end
