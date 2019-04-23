/*****************************************************************************
 * rqdMediaCloudStorageTableViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaCloudStorageTableViewController.h"
#import "rqdMediaCloudStorageTableViewCell.h"
#import "rqdMediaProgressView.h"

@interface rqdMediaCloudStorageTableViewController()
{
    rqdMediaProgressView *_progressView;
    UIRefreshControl *_refreshControl;

    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_logoutButton;
}

@end

@implementation rqdMediaCloudStorageTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _authorizationInProgress = NO;

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    UIBarButtonItem *backButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;

    _logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_LOGOUT", "") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];

    [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];

    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"sudHeaderBg"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    self.tableView.separatorColor = [UIColor rqdMediaDarkBackgroundColor];
    self.tableView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    self.view.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    self.tableView.rowHeight = [rqdMediaCloudStorageTableViewCell heightOfCell];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

    _progressView = [rqdMediaProgressView new];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];

    [self _showProgressInToolbar:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [super viewWillDisappear:animated];
}

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];

    [self requestInformationForCurrentPath];
}

- (void)requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [self.controller requestDirectoryListingAtPath:self.currentPath];
}

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];
    [_refreshControl endRefreshing];

    [self.tableView reloadData];

    NSUInteger count = self.controller.currentListFiles.count;
    if (count == 0)
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", nil);
    else if (count != 1)
        self.numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), count];
    else
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", nil);
}

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value)
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    else {
        _progressView.progressBar.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}

- (void)updateRemainingTime:(NSString *)time
{
    [_progressView updateTime:time];
}

- (void)currentProgressInformation:(CGFloat)progress
{
    [_progressView.progressBar setProgress:progress animated:YES];
}

- (void)operationWithProgressInformationStarted
{
    [self _showProgressInToolbar:YES];
}

- (void)operationWithProgressInformationStopped
{
    [self _showProgressInToolbar:NO];
}
#pragma mark - UITableViewDataSources

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.controller.currentListFiles.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor rqdMediaDarkBackgroundColor];
}

- (void)goBack
{
    if (((![self.currentPath isEqualToString:@""] && ![self.currentPath isEqualToString:@"/"]) && [self.currentPath length] > 0) && [self.controller isAuthorized]){
        self.currentPath = [self.currentPath stringByDeletingLastPathComponent];
        [self requestInformationForCurrentPath];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)showLoginPanel
{
    self.loginToCloudStorageView.frame = self.tableView.frame;
    self.navigationItem.rightBarButtonItem = nil;
    [self.tableView addSubview:self.loginToCloudStorageView];
}

- (void)updateViewAfterSessionChange
{
    if (self.controller.canPlayAll) {
        self.navigationItem.rightBarButtonItems = @[_logoutButton, [UIBarButtonItem themedPlayAllButtonWithTarget:self andSelector:@selector(playAllAction:)]];
    } else {
        self.navigationItem.rightBarButtonItem = _logoutButton;
    }

    if(_authorizationInProgress || [self.controller isAuthorized]) {
        if (self.loginToCloudStorageView.superview) {
            [self.loginToCloudStorageView removeFromSuperview];
        }
    }

    if (![self.controller isAuthorized]) {
        [_activityIndicator stopAnimating];
        [self showLoginPanel];
        return;
    }

    //reload if we didn't come back from streaming
    if (self.currentPath == nil) {
        self.currentPath = @"";
    }
    if([self.controller.currentListFiles count] == 0)
        [self requestInformationForCurrentPath];
}

- (void)logout
{
    [self.controller logout];
    [self updateViewAfterSessionChange];
}

- (IBAction)loginAction:(id)sender
{
}

- (IBAction)playAllAction:(id)sender
{
}

@end
