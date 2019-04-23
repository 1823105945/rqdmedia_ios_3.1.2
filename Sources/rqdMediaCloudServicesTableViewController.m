/*****************************************************************************
 * rqdMediaCloudServicesTableViewController.m
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

#import "rqdMediaCloudServicesTableViewController.h"
#import "rqdMediaDropboxTableViewController.h"
#import "rqdMediaGoogleDriveTableViewController.h"
#import "rqdMediaBoxTableViewController.h"
#import "rqdMediaBoxController.h"
#import "rqdMediaOneDriveTableViewController.h"
#import "rqdMediaOneDriveController.h"
#import "rqdMediaDocumentPickerController.h"
#import "rqdMediaCloudServiceCell.h"

#import "rqdMediaGoogleDriveController.h"

@interface rqdMediaCloudServicesTableViewController ()

@property (nonatomic) rqdMediaDropboxTableViewController *dropboxTableViewController;
@property (nonatomic) rqdMediaGoogleDriveTableViewController *googleDriveTableViewController;
@property (nonatomic) rqdMediaBoxTableViewController *boxTableViewController;
@property (nonatomic) rqdMediaOneDriveTableViewController *oneDriveTableViewController;
@property (nonatomic) rqdMediaDocumentPickerController *documentPickerController;

@end

@implementation rqdMediaCloudServicesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"CLOUD_SERVICES", "");

    [self.tableView registerNib:[UINib nibWithNibName:@"rqdMediaCloudServiceCell" bundle:nil] forCellReuseIdentifier:@"CloudServiceCell"];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack)];
    self.tableView.separatorColor = [UIColor rqdMediaDarkBackgroundColor];
    self.tableView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];

    self.dropboxTableViewController = [[rqdMediaDropboxTableViewController alloc] initWithNibName:@"rqdMediaCloudStorageTableViewController" bundle:nil];
    self.googleDriveTableViewController = [[rqdMediaGoogleDriveTableViewController alloc] initWithNibName:@"rqdMediaCloudStorageTableViewController" bundle:nil];
    [[rqdMediaBoxController sharedInstance] startSession];
    self.boxTableViewController = [[rqdMediaBoxTableViewController alloc] initWithNibName:@"rqdMediaCloudStorageTableViewController" bundle:nil];
    self.oneDriveTableViewController = [[rqdMediaOneDriveTableViewController alloc] initWithNibName:@"rqdMediaCloudStorageTableViewController" bundle:nil];
    self.documentPickerController = [rqdMediaDocumentPickerController new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationSessionsChanged:) name:rqdMediaOneDriveControllerSessionUpdated object:nil];
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)goBack
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
}

- (void)authenticationSessionsChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor rqdMediaDarkBackgroundColor];

    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    rqdMediaCloudServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CloudServiceCell" forIndexPath:indexPath];
    switch (indexPath.row) {
        case 0: {
            //Dropbox
            BOOL isAuthorized = [[rqdMediaDropboxController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Dropbox"];
            cell.cloudTitle.text = @"Dropbox";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 1: {
            //GoogleDrive
            BOOL isAuthorized = [[rqdMediaGoogleDriveController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Drive"];
            cell.cloudTitle.text = @"Google Drive";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 2: {
            //Box
            BOOL isAuthorized = [[BoxSDK sharedSDK].OAuth2Session isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"Box"];
            cell.cloudTitle.text = @"Box";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 3: {
            //OneDrive
            BOOL isAuthorized = [[rqdMediaOneDriveController sharedInstance] isAuthorized];
            cell.icon.image = [UIImage imageNamed:@"OneDrive"];
            cell.cloudTitle.text = @"OneDrive";
            cell.cloudInformation.text = isAuthorized ? NSLocalizedString(@"LOGGED_IN", "") : NSLocalizedString(@"LOGIN", "");
            cell.lonesomeCloudTitle.text = @"";
            break;
        }
        case 4:
            //Cloud Drives
            cell.icon.image = [UIImage imageNamed:@"iCloud"];
            cell.lonesomeCloudTitle.text = NSLocalizedString(@"CLOUD_SERVICES", nil);
            cell.cloudTitle.text = cell.cloudInformation.text = @"";
            break;
        default:
            break;
    }

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            //dropBox
            [self.navigationController pushViewController:self.dropboxTableViewController animated:YES];
            break;
        case 1:
            //GoogleDrive
            [self.navigationController pushViewController:self.googleDriveTableViewController animated:YES];
            break;
        case 2:
            //Box
           [self.navigationController pushViewController:self.boxTableViewController animated:YES];
            break;
        case 3:
            //OneDrive
            [self.navigationController pushViewController:self.oneDriveTableViewController animated:YES];
            break;
        case 4:
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                [self.documentPickerController showDocumentMenuViewController:[(rqdMediaCloudServiceCell *)[self.tableView cellForRowAtIndexPath:indexPath] icon]];
            else
                [self.documentPickerController showDocumentMenuViewController:nil];
            break;
        default:
            break;
    }
}

@end
