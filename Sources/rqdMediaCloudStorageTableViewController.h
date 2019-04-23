/*****************************************************************************
 * rqdMediaCloudStorageTableViewController.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaCloudStorageController.h"

@interface rqdMediaCloudStorageTableViewController : UIViewController <rqdMediaCloudStorageDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *loginToCloudStorageView;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIImageView *cloudStorageLogo;

@property (nonatomic, strong) UIBarButtonItem *numberOfFilesBarButtonItem;
@property (nonatomic, strong) rqdMediaCloudStorageController *controller;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic) BOOL authorizationInProgress;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (IBAction)loginAction:(id)sender;
- (IBAction)playAllAction:(id)sender;

- (void)requestInformationForCurrentPath;
- (void)showLoginPanel;
- (void)updateViewAfterSessionChange;
- (void)goBack;

@end
