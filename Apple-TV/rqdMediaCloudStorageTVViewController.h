/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaRemoteBrowsingCollectionViewController.h"
#import "rqdMediaCloudStorageController.h"

@interface rqdMediaCloudStorageTVViewController : rqdMediaRemoteBrowsingCollectionViewController

@property (nonatomic, strong) rqdMediaCloudStorageController *controller;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic) BOOL authorizationInProgress;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (void)updateViewAfterSessionChange;
- (void)requestInformationForCurrentPath;

@end
