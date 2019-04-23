/*****************************************************************************
 * rqdMediaOneDriveController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaOneDriveTableViewController.h"
#import "rqdMediaOneDriveObject.h"

#define rqdMediaOneDriveControllerSessionUpdated @"rqdMediaOneDriveControllerSessionUpdated"

@interface rqdMediaOneDriveController : rqdMediaCloudStorageController

@property (readonly) BOOL activeSession;
@property (nonatomic, readonly) rqdMediaOneDriveObject *rootFolder;
@property (nonatomic, readwrite) rqdMediaOneDriveObject *currentFolder;

+ (rqdMediaOneDriveController *)sharedInstance;

- (void)loginWithViewController:(UIViewController*)presentingViewController;

- (void)downloadObject:(rqdMediaOneDriveObject *)object;

- (void)loadCurrentFolder;

@end
