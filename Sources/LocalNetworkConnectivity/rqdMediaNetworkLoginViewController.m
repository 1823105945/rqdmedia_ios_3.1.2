/*****************************************************************************
 * rqdMediaNetworkLoginViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkLoginViewController.h"
#import "rqdMediaPlexWebAPI.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>

#import "rqdMediaNetworkLoginDataSource.h"
#import "rqdMediaNetworkLoginDataSourceProtocol.h"
#import "rqdMediaNetworkLoginDataSourceLogin.h"
#import "rqdMediaNetworkLoginDataSourceSavedLogins.h"
#import "rqdMediaNetworkServerLoginInformation.h"


// for protocol identifier
#import "rqdMediaLocalNetworkServiceBrowserPlex.h"
#import "rqdMediaLocalNetworkServiceBrowserFTP.h"
#import "rqdMediaLocalNetworkServiceBrowserDSM.h"


@interface rqdMediaNetworkLoginViewController () <UITextFieldDelegate, rqdMediaNetworkLoginDataSourceProtocolDelegate, rqdMediaNetworkLoginDataSourceLoginDelegate, rqdMediaNetworkLoginDataSourceSavedLoginsDelegate>
{
    UIActivityIndicatorView *_activityIndicator;
    UIView *_activityBackgroundView;
}

@property (nonatomic) rqdMediaNetworkLoginDataSource *dataSource;
@property (nonatomic) rqdMediaNetworkLoginDataSourceProtocol *protocolDataSource;
@property (nonatomic) rqdMediaNetworkLoginDataSourceLogin *loginDataSource;
@property (nonatomic) rqdMediaNetworkLoginDataSourceSavedLogins *savedLoginsDataSource;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation rqdMediaNetworkLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    self.title = NSLocalizedString(@"CONNECT_TO_SERVER", nil);

    self.tableView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    self.tableView.separatorColor = [UIColor blackColor];

    self.protocolDataSource = [[rqdMediaNetworkLoginDataSourceProtocol alloc] init];
    self.protocolDataSource.delegate = self;
    self.protocolDataSource.protocol = [self protocolForProtocolIdentifier:self.loginInformation.protocolIdentifier];
    self.loginDataSource = [[rqdMediaNetworkLoginDataSourceLogin alloc] init];
    self.loginDataSource.loginInformation = self.loginInformation;
    self.loginDataSource.delegate = self;
    self.savedLoginsDataSource = [[rqdMediaNetworkLoginDataSourceSavedLogins alloc] init];
    self.savedLoginsDataSource.delegate = self;

    rqdMediaNetworkLoginDataSource *dataSource = [[rqdMediaNetworkLoginDataSource alloc] init];
    dataSource.dataSources = @[self.protocolDataSource, self.loginDataSource, self.savedLoginsDataSource];
    [dataSource configureWithTableView:self.tableView];
    self.dataSource = dataSource;

    _activityBackgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    _activityBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _activityBackgroundView.hidden = YES;
    _activityBackgroundView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    [self.view addSubview:_activityBackgroundView];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    [_activityBackgroundView addSubview:_activityIndicator];
    [_activityIndicator setCenter:_activityBackgroundView.center];

//    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark -

- (rqdMediaServerProtocol)protocolForProtocolIdentifier:(NSString *)protocolIdentifier
{
    rqdMediaServerProtocol protocol = rqdMediaServerProtocolUndefined;
    if ([protocolIdentifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierFTP]) {
        protocol = rqdMediaServerProtocolFTP;
    } else if ([protocolIdentifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierSMB]) {
        protocol = rqdMediaServerProtocolSMB;
    } else if ([protocolIdentifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierPlex]) {
        protocol = rqdMediaServerProtocolPLEX;
    }
    return protocol;
}

- (nullable NSString *)protocolIdentifierForProtocol:(rqdMediaServerProtocol)protocol
{
    NSString *protocolIdentifier = nil;
    switch (protocol) {
        case rqdMediaServerProtocolFTP:
        {
            protocolIdentifier = rqdMediaNetworkServerProtocolIdentifierFTP;
            break;
        }
        case rqdMediaServerProtocolPLEX:
        {
            protocolIdentifier = rqdMediaNetworkServerProtocolIdentifierPlex;
            break;
        }
        case rqdMediaServerProtocolSMB:
        {
            protocolIdentifier = rqdMediaNetworkServerProtocolIdentifierSMB;
        }
        default:
            break;
    }
    return protocolIdentifier;
}

- (void)setLoginInformation:(rqdMediaNetworkServerLoginInformation *)loginInformation
{
    _loginInformation = loginInformation;
    self.protocolDataSource.protocol = [self protocolForProtocolIdentifier:loginInformation.protocolIdentifier];
    self.loginDataSource.loginInformation = loginInformation;
}

#pragma mark - rqdMediaNetworkLoginDataSourceProtocolDelegate
- (void)protocolDidChange:(rqdMediaNetworkLoginDataSourceProtocol *)protocolSection
{
    NSString *protocolIdentifier = [self protocolIdentifierForProtocol:protocolSection.protocol];
    rqdMediaNetworkServerLoginInformation *login = [rqdMediaNetworkServerLoginInformation newLoginInformationForProtocol:protocolIdentifier];
    login.address = self.loginInformation.address;
    login.username = self.loginInformation.username;
    login.password = self.loginInformation.password;
    self.loginDataSource.loginInformation = login;
}

#pragma mark - rqdMediaNetworkLoginDataSourceLoginDelegate

- (void)saveLoginDataSource:(rqdMediaNetworkLoginDataSourceLogin *)dataSource
{
    if (!self.protocolSelected)
        return;

    rqdMediaNetworkServerLoginInformation *login = dataSource.loginInformation;
    // TODO: move somewere else?
    // Normalize Plex login
    if ([login.protocolIdentifier isEqualToString:@"plex"]) {
        if (!login.address.length) {
            login.address = @"Account";
        }
        if (!login.port) {
            login.port = @32400;
        }
    }

    self.loginInformation = login;
    NSError *error = nil;
    if (![self.savedLoginsDataSource saveLogin:login error:&error]) {
        [[[rqdMediaAlertView alloc] initWithTitle:error.localizedDescription
                                    message:error.localizedFailureReason
                          cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil] show];
    }

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)connectLoginDataSource:(rqdMediaNetworkLoginDataSourceLogin *)dataSource
{
    if (!self.protocolSelected)
        return;

    rqdMediaNetworkServerLoginInformation *loginInformation = dataSource.loginInformation;
    self.loginInformation = loginInformation;

    [self.delegate loginWithLoginViewController:self loginInfo:dataSource.loginInformation];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (BOOL)protocolSelected
{
    if (self.protocolDataSource.protocol == rqdMediaServerProtocolUndefined) {
        rqdMediaAlertView *alertView = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"PROTOCOL_NOT_SELECTED", nil)
                                                              message:NSLocalizedString(@"PROTOCOL_NOT_SELECTED", nil)
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        return NO;
    }

    return YES;
}

#pragma mark - rqdMediaNetworkLoginDataSourceSavedLoginsDelegate
- (void)loginsDataSource:(rqdMediaNetworkLoginDataSourceSavedLogins *)dataSource selectedLogin:(rqdMediaNetworkServerLoginInformation *)login
{
    self.loginInformation = login;
}

@end
