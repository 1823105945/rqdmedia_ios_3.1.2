/*****************************************************************************
 * rqdMediaBoxController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <BoxSDK/BoxSDK.h>
#import "rqdMediaCloudStorageController.h"
#import "rqdMediaBoxConstants.h"

#define rqdMediaBoxControllerSessionUpdated @"rqdMediaBoxControllerSessionUpdated"

@interface rqdMediaBoxController : rqdMediaCloudStorageController

- (void)stopSession;
- (void)downloadFileToDocumentFolder:(BoxFile *)file;
- (BOOL)hasMoreFiles;

@end
