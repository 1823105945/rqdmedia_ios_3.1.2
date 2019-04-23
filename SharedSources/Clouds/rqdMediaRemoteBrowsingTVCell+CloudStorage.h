/*****************************************************************************
 * rqdMediaRemoteBrowsingTVCell+CloudStorage.h
 * rqdMedia for tvOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaRemoteBrowsingTVCell.h"

#import "rqdMediaDropboxController.h"
#import "rqdMediaOneDriveObject.h"
#import <BoxSDK/BoxSDK.h>

@interface rqdMediaRemoteBrowsingTVCell (CloudStorage)

- (void)setDropboxFile:(DBFILESMetadata *)dropboxFile;
- (void)setBoxFile:(BoxItem *)boxFile;
- (void)setOneDriveFile:(rqdMediaOneDriveObject *)oneDriveFile;

@end
