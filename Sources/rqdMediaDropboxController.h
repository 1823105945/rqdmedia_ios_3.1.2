/*****************************************************************************
 * rqdMediaDropboxController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaCloudStorageController.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface rqdMediaDropboxController : rqdMediaCloudStorageController

@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;

+ (instancetype)sharedInstance;

- (void)shareCredentials;
- (BOOL)restoreFromSharedCredentials;

- (void)downloadFileToDocumentFolder:(DBFILESMetadata *)file;
- (void)streamFile:(DBFILESMetadata *)file currentNavigationController:(UINavigationController *)navigationController;

- (void)reset;

@end
