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

#import "rqdMediaCloudServicesTVViewController.h"
#import "rqdMediaDropboxController.h"
#import "rqdMediaDropboxCollectionViewController.h"
#import "rqdMediaPlayerDisplayController.h"
#import "rqdMediaOneDriveController.h"
#import "rqdMediaOneDriveCollectionViewController.h"
#import "rqdMediaBoxCollectionViewController.h"
#import "rqdMediaBoxController.h"
#import "MetaDataFetcherKit.h"

@interface rqdMediaCloudServicesTVViewController ()
{
    rqdMediaOneDriveController *_oneDriveController;
    rqdMediaBoxController *_boxController;
}
@end

@implementation rqdMediaCloudServicesTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.helpLabel.text = NSLocalizedString(@"CLOUD_LOGIN_LONG", nil);
    [self.helpLabel sizeToFit];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(oneDriveSessionUpdated:) name:rqdMediaOneDriveControllerSessionUpdated object:nil];
    [center addObserver:self selector:@selector(boxSessionUpdated:) name:rqdMediaBoxControllerSessionUpdated object:nil];

    MDFMovieDBSessionManager *movieDBSessionManager = [MDFMovieDBSessionManager sharedInstance];
    movieDBSessionManager.apiKey = krqdMediafortvOSMovieDBKey;
    [movieDBSessionManager fetchProperties];

    _oneDriveController = [rqdMediaOneDriveController sharedInstance];
    _boxController = [rqdMediaBoxController sharedInstance];
    [_boxController startSession];

    self.dropboxButton.enabled = self.gDriveButton.enabled = NO;
    [self oneDriveSessionUpdated:nil];
    [self boxSessionUpdated:nil];

    [self performSelector:@selector(updateDropbox) withObject:nil afterDelay:0.1];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)title
{
    return NSLocalizedString(@"CLOUD_SERVICES", nil);
}

- (IBAction)dropbox:(id)sender
{
    rqdMediaDropboxCollectionViewController *targetViewController = [[rqdMediaDropboxCollectionViewController alloc] initWithNibName:@"rqdMediaRemoteBrowsingCollectionViewController" bundle:nil];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (void)updateDropbox
{
    self.dropboxButton.enabled = [[rqdMediaDropboxController sharedInstance] restoreFromSharedCredentials];
}

- (void)oneDriveSessionUpdated:(NSNotification *)aNotification
{
    self.oneDriveButton.enabled = _oneDriveController.activeSession;
}

- (void)boxSessionUpdated:(NSNotification *)aNotification
{
    self.boxButton.enabled = YES;
}

- (IBAction)onedrive:(id)sender
{
    rqdMediaOneDriveCollectionViewController *targetViewController = [[rqdMediaOneDriveCollectionViewController alloc] initWithOneDriveObject:nil];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (IBAction)box:(id)sender
{
    rqdMediaBoxCollectionViewController *targetViewController = [[rqdMediaBoxCollectionViewController alloc] initWithPath:@""];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (IBAction)gdrive:(id)sender
{
    // TODO
}

@end
