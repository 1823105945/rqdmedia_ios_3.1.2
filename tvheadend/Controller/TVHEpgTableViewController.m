//
//  TVHEpgTableViewController.m
//  TvhClient
//
//  Created by Luis Fernandes on 3/10/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHEpgTableViewController.h"
#import "TVHProgramDetailViewController.h"
#import "TVHEpgStore.h"
#import "TVHChannelStore.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "TVHImageCache.h"
#import "TVHSingletonServer.h"
#import "TVHShowNotice.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "TVHSettingsGenericFieldViewController.h"
#import "TVHProgressBar.h"
#import "TVHSettings.h"
#import "Header.h"

@interface TVHEpgTableViewController () <TVHEpgStoreDelegate, UISearchBarDelegate> {
    NSDateFormatter *dateFormatter;
    NSDateFormatter *hourFormatter;
    NIKFontAwesomeIconFactory *factory;
    __weak UIPopoverController *myPopover;
}
@property (nonatomic, strong) id <TVHEpgStore> epgStore;
@property (nonatomic, strong) NSArray *epgTable ;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation TVHEpgTableViewController {
    BOOL shouldBeginEditing;
}

- (id <TVHEpgStore>)epgStore {
    if ( !_epgStore ) {
        // we need a DIFFERENT epgstore, because of the delegate
        // should we change this to a notification? this epgstore SHOULD be shared!!
        TVHServer *server = [TVHSingletonServer sharedServerInstance];
        _epgStore = [server createEpgStoreWithName:@"Shared"];
        [_epgStore setDelegate:self];
        // we can't have the object register the notification, because every channel has one epgStore - that would make every epgStore object update itself!!
        [[NSNotificationCenter defaultCenter] addObserver:_epgStore
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self startTimer];
    }
    return _epgStore;
}

- (void)appWillResignActive:(NSNotification*)note {
    [self stopTimer];
}

- (void)appWillEnterForeground:(NSNotification*)note {
    [self processTimerEvents];
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(processTimerEvents) userInfo:nil repeats:NO];
}

- (void)processTimerEvents {
    if ( self.epgStore ) {
        [self.epgStore removeOldProgramsFromStore];
        [self startTimer];
        [self.tableView reloadData];
    }
}

- (void)stopTimer
{
    if ( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"E d MMM, HH:mm"];
    
    hourFormatter = [[NSDateFormatter alloc] init];
    hourFormatter.dateFormat = @"HH:mm";
    
    factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
    factory.size = 16;
    factory.colors = @[[UIColor grayColor], [UIColor lightGrayColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetEpgStore)
                                                 name:TVHWillDestroyServerNotification
                                               object:nil];
    [self.searchBar setDelegate:self];
    shouldBeginEditing = YES;
    self.title = NSLocalizedString(@"Now", @"");
    self.searchBar.placeholder = NSLocalizedString(@"Search Program Title", @"");
    [self.filterSegmentedControl setTitle:NSLocalizedString(@"Channel", nil) forSegmentAtIndex:0];
    [self.filterSegmentedControl setTitle:NSLocalizedString(@"Tag", nil) forSegmentAtIndex:1];
    
    if ( ! self.splitViewController ) {
        // iPad has a setFilter which triggers the downloadEpgList, we don't want to call this again!
        [self.epgStore downloadEpgList];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [TVHAnalytics sendView:NSStringFromClass([self class])];
    [self resizeSegmentsToFitTitles:self.filterSegmentedControl];
    [super viewDidAppear:animated];
}

- (void)viewDidUnload
{
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setFilterToolBar:nil];
    [self setFilterSegmentedControl:nil];
    [self setSearchBar:nil];
    self.epgStore = nil;
    self.epgTable = nil;
    self.tableView = nil;
    [super viewDidUnload];
}

- (void)resetEpgStore {
    self.epgTable = nil;
    self.epgStore = nil;
    [self.tableView reloadData];
    [self.epgStore downloadEpgList];
}

- (void)resizeSegmentsToFitTitles:(UISegmentedControl*)segCtrl {
    CGFloat totalWidths = 0;    // total of all label text widths
    NSUInteger nSegments = segCtrl.subviews.count;
    UIView* aSegment = [segCtrl.subviews objectAtIndex:0];
    UIFont* theFont = nil;
    
    for (UILabel* aLabel in aSegment.subviews) {
        if ([aLabel isKindOfClass:[UILabel class]]) {
            theFont = aLabel.font;
            break;
        }
    }
    
    // calculate width that all the title text takes up
    for (NSUInteger i=0; i < nSegments; i++) {
        CGFloat textWidth = [[segCtrl titleForSegmentAtIndex:i] sizeWithFont:theFont].width;
        totalWidths += textWidth;
    }
    
    // width not used up by text, its the space between labels
    CGFloat spaceWidth = segCtrl.bounds.size.width - totalWidths;
    
    // now resize the segments to accomodate text size plus
    // give them each an equal part of the leftover space
    for (NSUInteger i=0; i < nSegments; i++) {
        // size for label width plus an equal share of the space
        CGFloat textWidth = [[segCtrl titleForSegmentAtIndex:i] sizeWithFont:theFont].width;
        // roundf??  the control leaves 1 pixel gap between segments if width
        // is not an integer value, the roundf fixes this
        CGFloat segWidth = roundf(textWidth + (spaceWidth / nSegments));
        [segCtrl setWidth:segWidth forSegmentAtIndex:i];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.epgTable count];
}

- (void)setScheduledIcon:(UIImageView*)schedStatusIcon forEpg:(TVHEpg*)epg {
    factory.colors = @[[UIColor grayColor], [UIColor lightGrayColor]];
    [schedStatusIcon setImage:nil];
    if ( [[epg schedstate] isEqualToString:@"scheduled"] ) {
        [schedStatusIcon setImage:[factory createImageForIcon:NIKFontAwesomeIconClockO]];
    }
    if ( [[epg schedstate] isEqualToString:@"recording"] ) {
        factory.colors = @[[UIColor redColor]];
        [schedStatusIcon setImage:[factory createImageForIcon:NIKFontAwesomeIconBullseye]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpgTableCellItems" forIndexPath:indexPath];
    
    TVHEpg *epg = [self.epgTable objectAtIndex:indexPath.row];
    
    UILabel *programLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:101];
    __weak UIImageView *channelImage = (UIImageView *)[cell viewWithTag:102];
    UILabel *channelName = (UILabel *)[cell viewWithTag:103];
    UIImageView *schedStatusImage = (UIImageView *)[cell viewWithTag:104];
    TVHProgressBar *currentTimeProgress = (TVHProgressBar *)[cell viewWithTag:105];
        
    programLabel.text = epg.fullTitle;
    timeLabel.text = [NSString stringWithFormat:@"%@ - %@ (%ld min)", [dateFormatter stringFromDate:epg.start], [hourFormatter stringFromDate:epg.end], epg.duration/(long)60 ];
    channelName.text = [epg.channelObject name];
    channelImage.contentMode = UIViewContentModeScaleAspectFit;
    [channelImage sd_setImageWithURL:[NSURL URLWithString:epg.chicon] placeholderImage:[UIImage imageNamed:@"tv2.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!error && image) {
            channelImage.image = [TVHImageCache resizeImage:image];
        }
    } ];
    [currentTimeProgress setHidden:YES];
    
    if ( [[TVHSettings sharedInstance] useBlackBorders] ) {
        // rouding corners - this makes the animation in ipad become VERY SLOW!!!
        //channelImage.layer.cornerRadius = 2.0f;
        channelImage.layer.masksToBounds = NO;
        channelImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
        channelImage.layer.borderWidth = 0.4;
        channelImage.layer.shouldRasterize = YES;
    } else {
        channelImage.layer.borderWidth = 0;
    }
    
    float progress = [epg progress];
    if ( progress > 0 && progress <= 1 ) {
        CGRect progressBarFrame = {
            .origin.x = currentTimeProgress.frame.origin.x,
            .origin.y = currentTimeProgress.frame.origin.y,
            .size.width = currentTimeProgress.frame.size.width,
            .size.height = 4,
        };
        [currentTimeProgress setFrame:progressBarFrame];
        [currentTimeProgress setHidden:NO];
        [currentTimeProgress setProgress:progress];
        if ( progress < 0.9 ) {
            [currentTimeProgress setTintColor:PROGRESS_BAR_PLAYBACK];
        } else {
            [currentTimeProgress setTintColor:PROGRESS_BAR_NEAR_END_PLAYBACK];
        }
             
         // if it's recording, let's put the bar red =)
         if ( [epg isRecording] ) {
             [currentTimeProgress setTintColor:PROGRESS_BAR_RECORDING];
         }
    }
    
    [self setScheduledIcon:schedStatusImage forEpg:epg];
    
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@", epg.fullTitle, NSLocalizedString(@"in",@"accessibility"), epg.channel,NSLocalizedString(@"starts at",@"accessibility"),[dateFormatter stringFromDate:epg.start], NSLocalizedString(@"finishes at",@"accessibility"),[dateFormatter stringFromDate:epg.end] ];
    
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.row == [self.epgTable count] - 1 ) {
        [self.epgStore downloadMoreEpgList];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( [self.epgTable objectAtIndex:indexPath.row] ) {
        [self performSegueWithIdentifier:@"Show Program Detail from EPG" sender:self];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)reloadData:(id <TVHEpgStore>)epgStore {
    [self.refreshControl endRefreshing];
    self.epgTable = [epgStore epgStoreItems];
    [self.tableView reloadData];
}

- (void)willLoadEpg {
    [TVHStatusBar setStatusText:@"Loading EPG..." timeout:2.0 animated:YES];
}

- (void)didLoadEpg {
    [TVHStatusBar clearStatusAnimated:YES];
    [self.refreshControl endRefreshing];
    self.epgTable = [[self.epgStore epgStoreItems] copy];
    [self.tableView reloadData];
}

- (void)didErrorLoadingEpgStore:(NSError *)error {
    [TVHShowNotice errorNoticeInView:self.view title:NSLocalizedString(@"Network Error", nil) message:error.localizedDescription];
    [self.refreshControl endRefreshing];
}

- (void)pullToRefreshViewShouldRefresh
{
    [self.epgStore downloadMoreEpgList];
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Show Program Detail from EPG"]) {
        
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        TVHEpg *epg = [self.epgTable objectAtIndex:path.row];
        
        TVHProgramDetailViewController *programDetail = segue.destinationViewController;
        [programDetail setChannel:[epg channelObject]];
        [programDetail setEpg:epg];
        [programDetail setTitle:epg.title];
    }
    
    if([segue.identifier isEqualToString:@"Select Filter Pref"]) {
        if (IS_IPAD) {
            myPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
        }
        
        TVHSettingsGenericFieldViewController *vc = segue.destinationViewController;
        NSInteger clickedFilterButton = [self.filterSegmentedControl selectedSegmentIndex];
        if ( clickedFilterButton == 0 ) {
            id <TVHChannelStore> channelStore = [[TVHSingletonServer sharedServerInstance] channelStore];
            NSArray *objectChannelList = [channelStore channels];
            NSMutableArray *list = [[NSMutableArray alloc] init];
            [list addObject:NSLocalizedString(@"All Channels", nil)];
            [objectChannelList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [list addObject:[obj name]];
            }];
            
            [vc setTitle:NSLocalizedString(@"Channel", nil)];
            [vc setSectionHeader:NSLocalizedString(@"Channel", nil)];
            [vc setOptions:list];
            [vc setSelectedOption:[list indexOfObject:[self.filterSegmentedControl titleForSegmentAtIndex:0]]];
            [vc setResponseBack:^(NSInteger order) {
                NSString *text = [list objectAtIndex:order];
                if ( [text isEqualToString:NSLocalizedString(@"All Channels", nil)] ) {
                    [self setFilterChannelName:nil];
                } else {
                    [self setFilterChannelName:text];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
                if (myPopover)
                    [myPopover dismissPopoverAnimated:YES];
            }];


        }
        
        if ( clickedFilterButton == 1 ) {
            id <TVHTagStore> tagStore = [[TVHSingletonServer sharedServerInstance] tagStore];
            NSArray *objectStoreList = [tagStore tags];
            NSMutableArray *list = [[NSMutableArray alloc] init];
            [objectStoreList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [list addObject:[obj name]];
            }];
            
            [vc setTitle:NSLocalizedString(@"Tag", nil)];
            [vc setSectionHeader:NSLocalizedString(@"Tag", nil)];
            [vc setOptions:list];
            [vc setSelectedOption:[list indexOfObject:[self.filterSegmentedControl titleForSegmentAtIndex:1]]];
            [vc setResponseBack:^(NSInteger order) {
                NSString *text = [list objectAtIndex:order];
                if ( order == 0 ) {
                    [self setFilterTag:nil];
                } else {
                    [self setFilterTag:text];
                }
                [self dismissViewControllerAnimated:YES completion:nil];
                if (myPopover)
                    [myPopover dismissPopoverAnimated:YES];
            }];
            
            
        }
    }
}

#pragma mark - search bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if( ![searchBar isFirstResponder] ) {
        shouldBeginEditing = NO;
        [self setFilterProgramTitle:@""];
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setFilterProgramTitleFromSearchBar:) object:searchBar];
    [self performSelector:@selector(setFilterProgramTitleFromSearchBar:) withObject:searchBar afterDelay:0.3];
    
    if ( [searchText isEqualToString:@""] ) {
        // why do I have to do this!??! if I put the resignFirstResponder here, it doesn't work...
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - epg filter

- (void)setFilterProgramTitleFromSearchBar:(UISearchBar *)searchbar {
    [self setFilterProgramTitle:searchbar.text];
}

- (void)setFilterProgramTitle:(NSString*)programTitle {
    [self.epgStore setFilterToProgramTitle:programTitle];
    [self.epgStore downloadEpgList];
}

- (void)setFilterChannelName:(NSString*)channelName{
    if( channelName ) {
        [self.filterSegmentedControl setTitle:channelName forSegmentAtIndex:0];
    } else {
        [self.filterSegmentedControl setTitle:NSLocalizedString(@"Channel", nil) forSegmentAtIndex:0];
    }
    
    TVHChannel *channel = [[[self.epgStore tvhServer] channelStore] channelWithName:channelName];
    [self.epgStore setFilterToChannel:channel];
    [self.epgStore downloadEpgList];
    [self resizeSegmentsToFitTitles:self.filterSegmentedControl];
}

- (void)setFilterTag:(NSString *)tag {
    // if tag is the same, we should not redo the whole thing?
    if( tag ) {
        [self.filterSegmentedControl setTitle:tag forSegmentAtIndex:1];
    } else {
        [self.filterSegmentedControl setTitle:NSLocalizedString(@"Tag", nil) forSegmentAtIndex:1];
    }
    [self.epgStore setFilterToTagName:tag];
    [self.epgStore downloadEpgList];
    [self resizeSegmentsToFitTitles:self.filterSegmentedControl];
}

- (void)setFilterContentType:(NSString *)contentType {
    if( contentType ) {
        [self.filterSegmentedControl setTitle:contentType forSegmentAtIndex:2];
    } else {
        [self.filterSegmentedControl setTitle:NSLocalizedString(@"Content Type", nil) forSegmentAtIndex:2];
    }
    [self.epgStore setFilterToContentTypeId:contentType];
    [self.epgStore downloadEpgList];
}

- (IBAction)filterSegmentedControlClicked:(UISegmentedControl *)sender {
    if (myPopover) {
        [myPopover dismissPopoverAnimated:YES];
    } else {
        [self performSegueWithIdentifier:@"Select Filter Pref" sender:sender];
    }
}

- (IBAction)showHideSegmentedBar:(UIBarButtonItem *)sender {
    if ( self.filterToolBar.hidden ) {
        self.filterToolBar.hidden = NO;
        [UIView animateWithDuration:.5
                         animations:^(void) {
                             CGRect toolbarFrame = self.filterToolBar.frame;
                             toolbarFrame.origin.y = 0;
                             self.filterToolBar.frame = toolbarFrame;
                             
                             CGRect tableFrame = self.tableView.frame;
                             tableFrame.origin.y = 44;
                             tableFrame.size.height = self.view.frame.size.height;
                             self.tableView.frame = tableFrame;
                         }
                         completion:^(BOOL finished) {
                         }
         ];
    } else {
        [UIView animateWithDuration:.5
                         animations:^(void) {
                             CGRect toolbarFrame = self.filterToolBar.frame;
                             toolbarFrame.origin.y = -44; 
                             self.filterToolBar.frame = toolbarFrame;
                             
                             CGRect tableFrame = self.tableView.frame;
                             tableFrame.origin.y = 0;
                             tableFrame.size.height = self.view.frame.size.height;
                             self.tableView.frame = tableFrame;
                         }
                         completion:^(BOOL finished) {
                            self.filterToolBar.hidden = YES;
                        }
         ];
    }
}

@end
