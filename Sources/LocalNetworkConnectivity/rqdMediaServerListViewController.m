/*****************************************************************************
 * rqdMediaLocalServerListViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaServerListViewController.h"
#import "rqdMediaLocalServerDiscoveryController.h"

#import "VLCPlaybackController.h"
#import "rqdMediaNetworkListCell.h"
#import "rqdMediaNetworkLoginViewController.h"
#import "rqdMediaNetworkServerBrowserViewController.h"

#import "rqdMediaNetworkServerLoginInformation+Keychain.h"

#import "rqdMediaNetworkServerBrowserFTP.h"
#import "rqdMediaNetworkServerBrowserVLCMedia.h"
#import "rqdMediaNetworkServerBrowserPlex.h"

#import "rqdMediaLocalNetworkServiceBrowserManualConnect.h"
#import "rqdMediaLocalNetworkServiceBrowserPlex.h"
#import "rqdMediaLocalNetworkServiceBrowserFTP.h"
#import "rqdMediaLocalNetworkServiceBrowserUPnP.h"
#import "rqdMediaLocalNetworkServiceBrowserHTTP.h"
#import "rqdMediaLocalNetworkServiceBrowserSAP.h"
#import "rqdMediaLocalNetworkServiceBrowserDSM.h"
#import "rqdMediaLocalNetworkServiceBrowserBonjour.h"

@interface rqdMediaServerListViewController () <UITableViewDataSource, UITableViewDelegate, rqdMediaLocalServerDiscoveryControllerDelegate, rqdMediaNetworkLoginViewControllerDelegate>
{
    rqdMediaLocalServerDiscoveryController *_discoveryController;

    UIBarButtonItem *_backToMenuButton;

    UIRefreshControl *_refreshControl;
    UIActivityIndicatorView *_activityIndicator;
}

@end

@implementation rqdMediaServerListViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view = _tableView;
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.center = _tableView.center;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicator];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *browserClasses = @[
                                [rqdMediaLocalNetworkServiceBrowserManualConnect class],
                                [rqdMediaLocalNetworkServiceBrowserUPnP class],
                                [rqdMediaLocalNetworkServiceBrowserPlex class],
                                [rqdMediaLocalNetworkServiceBrowserFTP class],
                                [rqdMediaLocalNetworkServiceBrowserHTTP class],
#ifndef NDEBUG
                                [rqdMediaLocalNetworkServiceBrowserSAP class],
#endif
                                [rqdMediaLocalNetworkServiceBrowserDSM class],
                                [rqdMediaLocalNetworkServiceBrowserBonjour class],
                                ];

    _discoveryController = [[rqdMediaLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:browserClasses];
    _discoveryController.delegate = self;

//    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
//    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [rqdMediaNetworkListCell heightOfCell];
    self.tableView.separatorColor = [UIColor rqdMediaDarkBackgroundColor];
    self.view.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];

    self.title = NSLocalizedString(@"LOCAL_NETWORK", nil);

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];

    [_discoveryController stopDiscovery];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_discoveryController startDiscovery];
}

- (IBAction)goBack:(id)sender
{
    [_discoveryController stopDiscovery];
    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - table view handling

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _discoveryController.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_discoveryController numberOfItemsInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(rqdMediaNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor rqdMediaDarkBackgroundColor];
    cell.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor = color;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor colorWithRed:(130.0f/255.0f) green:(130.0f/255.0f) blue:(130.0f/255.0f) alpha:1.0f]];
    header.textLabel.font = [UIFont boldSystemFontOfSize:([UIFont systemFontSize] * 0.8f)];

    header.tintColor = [UIColor colorWithRed:(60.0f/255.0f) green:(60.0f/255.0f) blue:(60.0f/255.0f) alpha:1.0f];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCell";

    rqdMediaNetworkListCell *cell = (rqdMediaNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [rqdMediaNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    id<rqdMediaLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    [cell setIsDirectory:YES];
    [cell setIcon:service.icon];
    [cell setTitle:service.title];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    id<rqdMediaLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];

    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id<rqdMediaNetworkServerBrowser> serverBrowser = [service serverBrowser];
        if (serverBrowser) {
            rqdMediaNetworkServerBrowserViewController *vc = [[rqdMediaNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {
        NSURL *playbackURL = [service directPlaybackURL];
        if (playbackURL) {

            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:[VLCMedia mediaWithURL:playbackURL]];
            [[rqdMediaPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
            return;
        }
    }

    rqdMediaNetworkServerLoginInformation *login;
    if ([service respondsToSelector:@selector(loginInformation)]) {
        login = [service loginInformation];
    }

    [login loadLoginInformationFromKeychainWithError:nil];

    rqdMediaNetworkLoginViewController *loginViewController = [[rqdMediaNetworkLoginViewController alloc] initWithNibName:@"rqdMediaNetworkLoginViewController" bundle:nil];

    loginViewController.loginInformation = login;
    loginViewController.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        navCon.navigationBarHidden = NO;
        navCon.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navCon animated:YES completion:nil];

        if (loginViewController.navigationItem.leftBarButtonItem == nil)
            loginViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_DONE", nil) target:self andSelector:@selector(_dismissLogin)];
    } else {
        [self.navigationController pushViewController:loginViewController animated:YES];
    }
}

- (void)_dismissLogin
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Refresh

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing

    if ([_discoveryController refreshDiscoveredData])
        [self.tableView reloadData];

    [_refreshControl endRefreshing];
}

#pragma mark - rqdMediaNetworkLoginViewControllerDelegate

- (void)loginWithLoginViewController:(rqdMediaNetworkLoginViewController *)loginViewController loginInfo:(rqdMediaNetworkServerLoginInformation *)loginInformation
{
    id<rqdMediaNetworkServerBrowser> serverBrowser = nil;
    NSString *identifier = loginInformation.protocolIdentifier;

    if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [[rqdMediaNetworkServerBrowserFTP alloc] initWithLogin:loginInformation];
    } else if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[rqdMediaNetworkServerBrowserPlex alloc] initWithLogin:loginInformation];
    } else if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [rqdMediaNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:loginInformation];
    } else {
        APLog(@"Unsupported URL Scheme requested %@", identifier);
    }

    [self _dismissLogin];

    if (serverBrowser) {
        rqdMediaNetworkServerBrowserViewController *targetViewController = [[rqdMediaNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
}

- (void)discoveryFoundSomethingNew
{
    [self.tableView reloadData];
}

#pragma mark - custom table view appearance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // always hide the header of the first section
    if (section == 0)
        return 0.;

    if ([_discoveryController numberOfItemsInSection:section] == 0)
        return 0.;

    return 21.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_discoveryController titleForSection:section];
}

@end
