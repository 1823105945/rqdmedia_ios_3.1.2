/*****************************************************************************
 * rqdMediaDropboxTableViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Tamas Timar <ttimar.rqdmedia # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaDropboxTableViewController.h"
#import "rqdMediaDropboxController.h"
#import "rqdMediaCloudStorageTableViewCell.h"
#import "UIDevice+rqdMedia.h"
#import "rqdMediaAppDelegate.h"

@interface rqdMediaDropboxTableViewController () <rqdMediaCloudStorageTableViewCell, rqdMediaCloudStorageDelegate>
{
    rqdMediaDropboxController *_dropboxController;
    DBFILESMetadata *_selectedFile;
    NSArray *_mediaList;
}

@end

@implementation rqdMediaDropboxTableViewController

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.currentPath = path;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dropboxController = [rqdMediaDropboxController sharedInstance];
    self.controller = _dropboxController;
    self.controller.delegate = self;

#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionWasUpdated:)
                                                 name:rqdMediaDropboxSessionWasAuthorized
                                               object:nil];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dropbox-white"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"dropbox-white.png"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
#else
    self.title = @"Dropbox";
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.controller = [rqdMediaDropboxController sharedInstance];
    self.controller.delegate = self;

    if (self.currentPath != nil)
        self.title = self.currentPath.lastPathComponent;

    [self updateViewAfterSessionChange];
    [self.tableView reloadData];
}

#pragma mark - interface interaction

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DropboxCell";

    rqdMediaCloudStorageTableViewCell *cell = (rqdMediaCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [rqdMediaCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    NSUInteger index = indexPath.row;
    if (_mediaList) {
        if (index < _mediaList.count) {
            cell.dropboxFile = _mediaList[index];
            cell.delegate = self;
        }
    }

    return cell;
}

- (void)mediaListUpdated
{
    _mediaList = [self.controller.currentListFiles copy];

    [super mediaListUpdated];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _mediaList[indexPath.row];
    if (![_selectedFile isKindOfClass:[DBFILESFolderMetadata class]])
        [_dropboxController streamFile:_selectedFile currentNavigationController:self.navigationController];
    else {
        /* dive into subdirectory */
        NSString *futurePath = [self.currentPath stringByAppendingFormat:@"/%@", _selectedFile.name];
        self.currentPath = futurePath;
        [self requestInformationForCurrentPath];
    }
    _selectedFile = nil;

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - login dialog

- (IBAction)loginAction:(id)sender
{
    if (!_dropboxController.isAuthorized) {
        self.authorizationInProgress = YES;

        [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                       controller:self
                                          openURL:^(NSURL *url) {
                                              [[UIApplication sharedApplication] openURL:url];
                                          }];
    } else
        [_dropboxController logout];
}

- (void)sessionWasUpdated:(NSNotification *)aNotification
{
    self.authorizationInProgress = YES;
    [self updateViewAfterSessionChange];

    [_dropboxController shareCredentials];
}

#pragma mark - rqdMediaCloudStorageTableViewCell delegation

#if TARGET_OS_IOS
- (void)triggerDownloadForCell:(rqdMediaCloudStorageTableViewCell *)cell
{
    _selectedFile = _mediaList[[self.tableView indexPathForCell:cell].row];

    if (((DBFILESFileMetadata *)_selectedFile).size.longLongValue < [[UIDevice currentDevice] rqdMediaFreeDiskSpace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.name, [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_dropboxController downloadFileToDocumentFolder:_selectedFile];

    _selectedFile = nil;
}

#endif

@end
