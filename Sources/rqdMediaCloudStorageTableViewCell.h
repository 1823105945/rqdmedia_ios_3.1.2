/*****************************************************************************
 * rqdMediaCloudStorageTableViewCell.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaDropboxController.h"
#import "rqdMediaOneDriveObject.h"
#import <BoxSDK/BoxSDK.h>
#if TARGET_OS_IOS
#import "GTLDrive.h"
#endif

@class rqdMediaNetworkImageView;

@interface rqdMediaCloudStorageTableViewCell : UITableViewCell

@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *folderTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet rqdMediaNetworkImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UIButton *downloadButton;

@property (nonatomic, retain) DBFILESMetadata *dropboxFile;
@property (nonatomic, retain) rqdMediaOneDriveObject *oneDriveFile;
@property (nonatomic, retain) BoxItem *boxFile;
#if TARGET_OS_IOS
@property (nonatomic, retain) GTLDriveFile *driveFile;
#endif

@property (nonatomic, readwrite) BOOL isDownloadable;

+ (rqdMediaCloudStorageTableViewCell *)cellWithReuseIdentifier:(NSString *)ident;
+ (CGFloat)heightOfCell;

- (IBAction)triggerDownload:(id)sender;

@end

@protocol rqdMediaCloudStorageTableViewCell <NSObject>

- (void)triggerDownloadForCell:(rqdMediaCloudStorageTableViewCell *)cell;

@end
