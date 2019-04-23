//
//  TVHTagListViewController.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/9/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHTagStoreViewController.h"
#import "TVHChannelStoreViewController.h"
#import "UIImageView+WebCache.h"
#import "TVHShowNotice.h"
#import "TVHImageCache.h"
#import "TVHEpgTableViewController.h"
#import "TVHSingletonServer.h"
#import <QuartzCore/QuartzCore.h>
#import "TVHSettings.h"
#import "UIActionSheet+Blocks.h"
#import "TVHStatusBar.h"
#import "TVHAnalytics.h"
#import "Header.h"
#import "TVHSettingsViewController.h"
#import "TVTagListTableItems.h"

static NSString *TagListTableItems=@"TagListTableItems";
@interface TVHTagStoreViewController () {
    BOOL didAlreadyPushed;
}
@property (weak, nonatomic) id <TVHTagStore> tagStore;
@property (strong, nonatomic) NSArray *tags;
@end

@implementation TVHTagStoreViewController

- (id <TVHTagStore>)tagStore {
    if ( _tagStore == nil) {
        _tagStore = [[TVHSingletonServer sharedServerInstance] tagStore];
    }
    return _tagStore;
}

- (void)resetControllerData {
    self.tags = nil;
    [self initDelegate];
    [self.tagStore fetchTagList];
}

- (void)updateServerName
{
    TVHSettings *settings = [TVHSettings sharedInstance];
    if( [settings selectedServer] != NSNotFound ) {
        self.serverButton.title = [settings serverProperty:TVHS_SERVER_NAME forServer:[settings selectedServer]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if ( self.splitViewController ) {
        UINavigationController *detailView = [self.splitViewController.viewControllers lastObject];
        [detailView popToRootViewControllerAnimated:YES];
    }
    [self prepareSplitViewEpg:nil];
    [super viewWillAppear:animated];
    didAlreadyPushed = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [TVHAnalytics sendView:NSStringFromClass([self class])];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.tableView);
    [super viewDidAppear:animated];
}

- (void)initDelegate {
    if( [self.tagStore delegate] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadTags)
                                                     name:TVHTagStoreDidLoadNotification
                                                   object:self.tagStore];
    } else {
        [self.tagStore setDelegate:self];
    }
 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initDelegate];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.tableView.tableFooterView=[UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVTagListTableItems" bundle:nil] forCellReuseIdentifier:TagListTableItems];
    [self reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetControllerData)
                                                 name:TVHWillDestroyServerNotification
                                               object:nil];
    self.settingsButton=[[UIBarButtonItem alloc]init];
    [self.settingsButton setAction:@selector(pushSetting)];
    [self.settingsButton setTarget:self];
    self.navigationItem.rightBarButtonItem=self.settingsButton;
    self.settingsButton.title = NSLocalizedString(@"Settings", @"");
    [self updateServerName];
}

    - (IBAction)goBack:(id)sender
    {
        [self.view endEditing:YES];
        [[rqdMediaSidebarController sharedInstance] toggleSidebar];
    }
    
- (void)viewDidUnload {
    self.tagStore = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setSettingsButton:nil];
    [super viewDidUnload];
}

- (void)pullToRefreshViewShouldRefresh {
    [self.tagStore fetchTagList];
}

- (void)reloadData {
    [self updateServerName];
    self.tags = [[self.tagStore tags] copy];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagListTableItems" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    TVHTag *tag = [self.tags objectAtIndex:indexPath.row];
    
    UILabel *tagNameLabel = (UILabel *)[cell viewWithTag:100];
	UILabel *tagNumberLabel = (UILabel *)[cell viewWithTag:101];
	__weak UIImageView *channelImage = (UIImageView *)[cell viewWithTag:102];
    tagNameLabel.text = tag.name;
    
    if ( ! DEVICE_HAS_IOS7 ){
        tagNumberLabel.frame = CGRectMake(tagNumberLabel.frame.origin.x, tagNumberLabel.frame.origin.y, 31, tagNumberLabel.frame.size.height);
    }
    tagNumberLabel.text = [NSString stringWithFormat:@"%ld", (long)[tag channelCount]];
    tagNumberLabel.layer.cornerRadius = 13.0;
    tagNumberLabel.layer.masksToBounds = YES;
    tagNumberLabel.layer.borderWidth = 1.f;
    tagNumberLabel.layer.borderColor = [tagNumberLabel.textColor CGColor];
    tagNumberLabel.adjustsFontSizeToFitWidth = YES;
    
    channelImage.contentMode = UIViewContentModeScaleAspectFit;
    [channelImage sd_setImageWithURL:[NSURL URLWithString:tag.icon] placeholderImage:[UIImage imageNamed:@"tag.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!error && image) {
            channelImage.image = [TVHImageCache resizeImage:image];
        }
    } ];
    
    cell.accessibilityLabel = tag.name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if ( ! DEVICE_HAS_IOS7 ) {
        UIView *sepColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width , 1)];
        [sepColor setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [cell.contentView addSubview:sepColor];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self pushChannelStoreViewController];
}

-(void)pushChannelStoreViewController{
    TVHChannelStoreViewController *channelStore = [[TVHChannelStoreViewController alloc]init];
    [self prepareChannelStoreView:channelStore];
}

- (void)prepareChannelStoreView:(TVHChannelStoreViewController*)channelStore {
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    TVHTag *tag = [self.tags objectAtIndex:path.row];
    
    [channelStore setFilterTagId:tag.idKey];
    [channelStore setTitle:tag.name];
    
    [self prepareSplitViewEpg:tag];
    [self.navigationController pushViewController:channelStore animated:YES];
}

- (void)prepareSplitViewEpg:(TVHTag*)tag {
    if ( self.splitViewController ) {
        UINavigationController *detailView = [self.splitViewController.viewControllers lastObject];
        [detailView popToRootViewControllerAnimated:YES];
        TVHEpgTableViewController *epgDetailView = [detailView.viewControllers lastObject];
        if (![epgDetailView isKindOfClass:[TVHEpgTableViewController class]]) {
            return;
        }
        [epgDetailView setFilterTag:tag.name];
        if ( tag ) {
            [epgDetailView setTitle:[@[NSLocalizedString(@"Now in", nil), tag.name] componentsJoinedByString:@" "]];
        } else {
            [epgDetailView setTitle:NSLocalizedString(@"Now", nil)];
        }
    }
}

- (void)willLoadTags {
    [TVHStatusBar setStatusText:@"Loading Tags..." timeout:2.0 animated:YES];
}

- (void)didLoadTags {
    [TVHStatusBar clearStatusAnimated:YES];
    [self reloadData];
    [self.refreshControl endRefreshing];
    
    if ( [self.view isEqual:self.navigationController.topViewController.view] && [self.tags count] == 1 && !didAlreadyPushed ) {
        didAlreadyPushed = YES;
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        [self pushChannelStoreViewController];
    }
}

- (void)didErrorLoadingTagStore:(NSError *)error
{
    [TVHShowNotice errorNoticeInView:self.view
                               title:NSLocalizedString(@"Network Error", nil)
                             message:error.localizedDescription];
    [self.refreshControl endRefreshing];
}

- (IBAction)changeServer:(id)sender {
    TVHSettings *settings = [TVHSettings sharedInstance];
    NSMutableArray *servers = [[NSMutableArray alloc] init];
    [[settings availableServers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [servers addObject:[obj objectForKey:TVHS_SERVER_NAME]];
    }];
    
    [UIActionSheet showFromBarButtonItem:sender
                                animated:YES
                               withTitle:NSLocalizedString(@"TVHeadend Server", nil)
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                  destructiveButtonTitle:nil
                       otherButtonTitles:servers
                                tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                    TVHSettings *settings = [TVHSettings sharedInstance];
                                    [settings setSelectedServer:buttonIndex];
                                }];
}
    
//    进入设置页面
-(void)pushSetting{
    [self.navigationController pushViewController:[TVHSettingsViewController alloc] animated:YES];
}
    
    
@end
