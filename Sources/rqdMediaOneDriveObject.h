/*****************************************************************************
 * rqdMediaOneDriveObject.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "LiveConnectClient.h"

@class rqdMediaOneDriveObject;

@protocol rqdMediaOneDriveObjectDelegate <NSObject>

- (void)folderContentLoaded:(rqdMediaOneDriveObject *)sender;

- (void)fullFolderTreeLoaded:(rqdMediaOneDriveObject *)sender;

- (void)folderContentLoadingFailed:(NSError *)error
                            sender:(rqdMediaOneDriveObject *) sender;
@end

@protocol rqdMediaOneDriveObjectDownloadDelegate <NSObject>

- (void)downloadStarted:(rqdMediaOneDriveObject *)object;
- (void)downloadEnded:(rqdMediaOneDriveObject *)object;
- (void)progressUpdated:(CGFloat)progress;
- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize;
@end

@interface rqdMediaOneDriveObject : NSObject <LiveOperationDelegate, LiveDownloadOperationDelegate, rqdMediaOneDriveObjectDelegate>

@property (strong, nonatomic) rqdMediaOneDriveObject *parent;
@property (strong, nonatomic) NSString *objectId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSNumber *size;
@property (strong, nonatomic) NSNumber *duration;
@property (strong, nonatomic) NSString *thumbnailURL;
@property (readonly, nonatomic) BOOL isFolder;
@property (readonly, nonatomic) BOOL isVideo;
@property (readonly, nonatomic) BOOL isAudio;

@property (strong, nonatomic) NSArray *folders;
@property (strong, nonatomic) NSArray *files;
@property (strong, nonatomic) NSArray *items;

@property (readonly, nonatomic) NSString *filesPath;
@property (strong, nonatomic) NSString *downloadPath;
@property (strong, nonatomic) NSString *subtitleURL;
@property (readonly, nonatomic) BOOL hasFullFolderTree;

@property (strong, nonatomic) LiveConnectClient *liveClient;
@property (strong, nonatomic) id<rqdMediaOneDriveObjectDelegate>delegate;
@property (strong, nonatomic) id<rqdMediaOneDriveObjectDownloadDelegate>downloadDelegate;

- (void)loadFolderContent;
- (void)saveObjectToDocuments;

@end
