//
//  TVHRecordingsViewController.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/27/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHRecordingsViewController.h"
#import "TVHShowNotice.h"
#import "TVHSettings.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "TVHRecordingsDetailViewController.h"
#import "TVHAutoRecDetailViewController.h"
#import "NSString+FileSize.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "TVHImageCache.h"
#import "TVHSingletonServer.h"
#import "TVHTableMgrActions.h"
#import "TVHStatusBar.h"
#import "VLCPlaybackController.h"

#define SEGMENT_UPCOMING_REC 0
#define SEGMENT_COMPLETED_REC 1
#define SEGMENT_FAILED_REC 2
#define SEGMENT_AUTOREC 3

@interface TVHRecordingsViewController () {
    NIKFontAwesomeIconFactory *factory;
}

@property (weak, nonatomic) id <TVHDvrStore> dvrStore;
@property (weak, nonatomic) id <TVHAutoRecStore> autoRecStore;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic,strong)VLCMediaList *medialist;
@end

@implementation TVHRecordingsViewController {
    NSDateFormatter *dateFormatter;
}

- (id <TVHDvrStore>)dvrStore {
    if ( _dvrStore == nil) {
        _dvrStore = [[TVHSingletonServer sharedServerInstance] dvrStore];
    }
    return _dvrStore;
}

- (id <TVHAutoRecStore>)autoRecStore {
    if ( _autoRecStore == nil) {
        _autoRecStore = [[TVHSingletonServer sharedServerInstance] autorecStore];
    }
    return _autoRecStore;
}

- (void)receiveDvrNotification:(NSNotification *) notification {
    if ( [[notification name] isEqualToString:TVHDvrActionDidSucceedNotification] ) {
        if ( [notification.object isEqualToString:@"deleteEntry"] || [notification.object isEqualToString:@"api/idnode/delete"]) {
            [TVHShowNotice successNoticeInView:self.view title:NSLocalizedString(@"Succesfully Deleted Recording", nil)];
        }
        else if([notification.object isEqualToString:@"cancelEntry"]) {
            [TVHShowNotice successNoticeInView:self.view title:NSLocalizedString(@"Succesfully Canceled Recording", nil)];
        }
        else if([notification.object isEqualToString:@"api/idnode/delete"]) {
            [TVHShowNotice successNoticeInView:self.view title:NSLocalizedString(@"Succesfully Deleted Auto Recording", nil)];
        }
    }
    // this is WRONG, there should be a specific notification for the autorec deleting
    if ( [[notification name] isEqualToString:TVHDidSuccessedTableMgrActionNotification] ) {
        if ( [notification.object isEqualToString:@"delete"] ) {
            [TVHShowNotice successNoticeInView:self.view title:NSLocalizedString(@"Succesfully Deleted Auto Recording", nil)];
        }
    }
}

- (void)initDelegate {
    if( [self.dvrStore delegate] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadDvr:)
                                                     name:TVHDvrStoreDidLoadNotification
                                                   object:self.dvrStore];
    } else {
        [self.dvrStore setDelegate:self];
    }
    
    if( [self.autoRecStore delegate] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadDvrAutoRec)
                                                     name:TVHAutoRecStoreDidLoadNotification
                                                   object:self.autoRecStore];
    } else {
        [self.autoRecStore setDelegate:self];
    }
}

- (void)resetRecordingsStore {
    [self initDelegate];
    [self.dvrStore fetchDvr];
    [self.autoRecStore fetchDvrAutoRec];
    
}

- (IBAction)goBack:(id)sender
{
    [self.view endEditing:YES];
    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVHRecordingsCell" bundle:nil] forCellReuseIdentifier:@"RecordStoreTableItems"];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"Edit" style:(UIBarButtonItemStylePlain) target:self action:@selector(putTableInEditMode:)];
    [self.dvrStore setDelegate:self];
    [self.dvrStore fetchDvr];
    
    [self.autoRecStore setDelegate:self];
    [self.autoRecStore fetchDvrAutoRec];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveDvrNotification:)
                                                 name:TVHDvrActionDidSucceedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveDvrNotification:)
                                                 name:TVHDidSuccessedTableMgrActionNotification
                                               object:nil];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"E d MMM, HH:mm"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetRecordingsStore)
                                                 name:TVHWillDestroyServerNotification
                                               object:nil];
    
    factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
    factory.size = 18;
    factory.colors = @[[UIColor grayColor]];
    [self.segmentedControl setImage:[factory createImageForIcon:NIKFontAwesomeIconClockO] forSegmentAtIndex:0];
    [self.segmentedControl setImage:[factory createImageForIcon:NIKFontAwesomeIconCheckCircleO] forSegmentAtIndex:1];
    [self.segmentedControl setImage:[factory createImageForIcon:NIKFontAwesomeIconMagic] forSegmentAtIndex:3];
    [self.segmentedControl setImage:[factory createImageForIcon:NIKFontAwesomeIconExclamationCircle] forSegmentAtIndex:2];
    
    [self.segmentedControl setTitle:NSLocalizedString(@"Upcoming", nil) forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"Completed", nil) forSegmentAtIndex:1];
    [self.segmentedControl setTitle:NSLocalizedString(@"Failed", nil) forSegmentAtIndex:2];
    [self.segmentedControl setTitle:NSLocalizedString(@"AutoRec", nil) forSegmentAtIndex:3];
    
    self.title = NSLocalizedString(@"Recordings", @"");
    
    if ( ! IS_IPAD ) {
        UISwipeGestureRecognizer *rightGesture = [[UISwipeGestureRecognizer alloc]
                                                  initWithTarget:self action:@selector(handleSwipeFromRight:)];
        [rightGesture setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.tableView addGestureRecognizer:rightGesture];
        
        UISwipeGestureRecognizer *leftGesture = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        [leftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.tableView addGestureRecognizer:leftGesture];
    }
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setSegmentedControl:nil];
    [self setTableView:nil];
    [self setDvrStore:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    TVHSettings *settings = [TVHSettings sharedInstance];
    if ( [settings programFirstRun] ) {
        [self.segmentedControl setSelectedSegmentIndex:3 ];
    }
//    [TVHAnalytics sendView:NSStringFromClass([self class])];
    [self.tableView setEditing:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
        if ( [self.autoRecStore count] == 0 ) {
            return NSLocalizedString(@"No auto recordings found.", nil);
        }
    } else {
        if ( [self.dvrStore count:self.segmentedControl.selectedSegmentIndex] == 0 ) {
            return NSLocalizedString(@"No recordings found.", nil);
        }
    }
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    //create the uiview container
    UIView *tfooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 45)];
    tfooterView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //create the uilabel for the text
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(_tableView.frame.size.width/2-120, 0, 240, 35)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:17];
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1];
    label.shadowColor = [UIColor whiteColor];
    label.text = [self tableView:self.tableView titleForFooterInSection:section];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    label.accessibilityLabel = [self tableView:self.tableView titleForFooterInSection:section];
    //add the label to the view
    [tfooterView addSubview:label];
    
    return tfooterView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
        return [self.autoRecStore count];
    } else {
        return [self.dvrStore count:self.segmentedControl.selectedSegmentIndex];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecordStoreTableItems" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:102];
    __weak UIImageView *channelImage = (UIImageView *)[cell viewWithTag:103];
    titleLabel.textColor = [UIColor blackColor];
    channelImage.contentMode = UIViewContentModeScaleAspectFit;
    
    if ( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
        TVHAutoRecItem *autoRecItem = [self.autoRecStore objectAtIndex:indexPath.row];
        titleLabel.text = autoRecItem.title;
        dateLabel.text = @"";
        statusLabel.text = [NSString stringOfWeekdaysLocalizedFromArray:autoRecItem.weekdays joinedByString:@","];
        TVHChannel *channel = [autoRecItem channelObject];
        
        if (channel) {
            dateLabel.text = channel.name;
            channelImage.contentMode = UIViewContentModeScaleAspectFit;
            [channelImage sd_setImageWithURL:[NSURL URLWithString:channel.imageUrl] placeholderImage:[UIImage imageNamed:@"tv2.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!error && image) {
                    channelImage.image = [TVHImageCache resizeImage:image];
                }
            } ];
        } else {
            [channelImage setImage:[UIImage imageNamed:@"tv2.png"]];
        }
        
        if ( [autoRecItem enabled] ) {
            titleLabel.textColor = [UIColor blackColor];
        } else {
            titleLabel.textColor = [UIColor grayColor];
        }
    } else {
        TVHDvrItem *dvrItem = [self.dvrStore objectAtIndex:indexPath.row forType:self.segmentedControl.selectedSegmentIndex];
        titleLabel.text = dvrItem.fullTitle;
        dateLabel.text = [NSString stringWithFormat:@"%@ (%ld min)", [dateFormatter stringFromDate:dvrItem.start], dvrItem.duration/(long)60 ];
        statusLabel.text = dvrItem.status;
        TVHChannel *channel = [dvrItem channelObject];
        if (channel) {
            [channelImage sd_setImageWithURL:[NSURL URLWithString:channel.imageUrl] placeholderImage:[UIImage imageNamed:@"tv2.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!error && image) {
                    channelImage.image = [TVHImageCache resizeImage:image];
                }
            } ];
        }
    }
    
    // rouding corners - this makes the animation in ipad become VERY SLOW!!!
    //channelImage.layer.cornerRadius = 5.0f;
    if ( [[TVHSettings sharedInstance] useBlackBorders] ) {
        channelImage.layer.masksToBounds = NO;
        channelImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
        channelImage.layer.borderWidth = 0.4;
        channelImage.layer.shouldRasterize = YES;
    } else {
        channelImage.layer.borderWidth = 0;
    }
    
    if ( ! DEVICE_HAS_IOS7 ) {
        UIView *sepColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width , 1)];
        [sepColor setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [cell.contentView addSubview:sepColor];
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if ( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
            TVHAutoRecItem *autoRecItem = [self.autoRecStore objectAtIndex:indexPath.row];
            [autoRecItem deleteAutoRec];
        } else {
            TVHDvrItem *dvrItem = [self.dvrStore objectAtIndex:indexPath.row forType:self.segmentedControl.selectedSegmentIndex];
            [dvrItem deleteRecording];
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
//        if ( [self.autoRecStore objectAtIndex:indexPath.row] ) {
//            TVHAutoRecDetailViewController *autoRecDetailViewController=[[TVHAutoRecDetailViewController alloc]initWithNibName:@"TVHAutoRecDetailViewController" bundle:nil];
//            TVHAutoRecItem *item = [self.autoRecStore objectAtIndex:indexPath.row];
//                [autoRecDetailViewController setTitle:[item title]];
//                [autoRecDetailViewController setItem:[item copy]];
//            [self.navigationController pushViewController:autoRecDetailViewController animated:YES];
//        }
//    } else {
//        if ( [self.dvrStore objectAtIndex:indexPath.row forType:self.segmentedControl.selectedSegmentIndex] ) {
//            TVHRecordingsDetailViewController *recordingsDetailViewController=[[TVHRecordingsDetailViewController alloc]initWithNibName:@"TVHRecordingsDetailViewController" bundle:nil];
//            TVHDvrItem *item = [self.dvrStore objectAtIndex:indexPath.row forType:self.segmentedControl.selectedSegmentIndex];
//                [recordingsDetailViewController setDvrItem:item];
//            [self.navigationController pushViewController:recordingsDetailViewController animated:YES];
//        }
//    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self playStream:indexPath];
}

- (IBAction)playStream:(NSIndexPath *)indexPath {
    self.medialist=[[VLCMediaList alloc] init];
    TVHDvrItem *item = [self.dvrStore objectAtIndex:indexPath.row forType:self.segmentedControl.selectedSegmentIndex];
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString: [[item streamUrlWithTranscoding:YES withInternal:NO] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    [self.medialist addMedia:media];
    [rqdMediaPlaybackController sharedInstance].dvrItem=item;
    [[rqdMediaPlaybackController sharedInstance] playMediaList:self.medialist firstIndex:0 subtitlesFilePath:nil];
}

- (void)handleSwipeFromRight:(UISwipeGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        NSInteger sel = [self.segmentedControl selectedSegmentIndex] -1;
        if (sel >= 0 ) {
            [self.segmentedControl setSelectedSegmentIndex:sel];
            [self segmentedDidChange:self.segmentedControl];
        }
    }
}

- (void)handleSwipeFromLeft:(UISwipeGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        NSInteger sel = [self.segmentedControl selectedSegmentIndex] + 1;
        if (sel < [self.segmentedControl numberOfSegments] ) {
            [self.segmentedControl setSelectedSegmentIndex:sel];
            [self segmentedDidChange:self.segmentedControl];
        }
    }
}

- (IBAction)segmentedDidChange:(id)sender {
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

- (void)pullToRefreshViewShouldRefresh
{
    [self.autoRecStore fetchDvrAutoRec];
    [self.dvrStore fetchDvr];
}

- (void)reloadData {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)willLoadDvr:(NSInteger)type {
    [TVHStatusBar setStatusText:@"Loading DVR Data..." timeout:2.0 animated:YES];
}

- (void)willLoadDvrAutoRec {
    [TVHStatusBar setStatusText:@"Loading AutoRec DVR Data..." timeout:2.0 animated:YES];
}

- (void)didLoadDvr:(NSInteger)type {
    if ( type == self.segmentedControl.selectedSegmentIndex ) {
        [TVHStatusBar clearStatusAnimated:YES];
        [self.refreshControl endRefreshing];
        [self reloadData];
    }
}

- (void)didLoadDvrAutoRec {
    if ( self.segmentedControl.selectedSegmentIndex == SEGMENT_AUTOREC ) {
        [TVHStatusBar clearStatusAnimated:YES];
        [self.refreshControl endRefreshing];
        [self reloadData];
    }
}

- (void)didErrorDvrStore:(NSError *)error {
    [TVHShowNotice errorNoticeInView:self.view title:NSLocalizedString(@"Network Error", nil) message:error.localizedDescription];
    [self.refreshControl endRefreshing];
}

- (void)didErrorDvrAutoStore:(NSError *)error {
    [self didErrorDvrStore:error];
}

- (IBAction)putTableInEditMode:(id)sender {
    if ( [self.tableView isEditing] ) {
        [self.tableView setEditing: NO animated: YES];
    } else {
        [self.tableView setEditing: YES animated: YES];
    }
    
}
@end
