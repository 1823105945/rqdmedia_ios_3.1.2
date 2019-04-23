//
//  TVHChannelListProgramsViewController.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/10/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannelStoreProgramsViewController.h"
#import "TVHProgramDetailViewController.h"
#import "TVHEpg.h"
#import "TVHShowNotice.h"
//#import "TVHPlayStreamHelpController.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "TVHProgressBar.h"
#import "Header.h"
#import "NSDate+Utilities.h"
#import "Masonry.h"
#import "VLCPlaybackController.h"

@interface TVHChannelStoreProgramsViewController () <TVHChannelDelegate, UIActionSheetDelegate> {
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    NIKFontAwesomeIconFactory *factory;
}
//@property (strong, nonatomic) TVHPlayStreamHelpController *help;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
//可播放频道对象
@property(nonatomic,strong)VLCMediaList *medialist;
@end

@implementation TVHChannelStoreProgramsViewController

- (void)viewDidAppear:(BOOL)animated
{
    [TVHAnalytics sendView:NSStringFromClass([self class])];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.tableView);
    [super viewDidAppear:animated];
}

- (void)initDelegate {
    if ( [self.channel delegate] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadEpgChannel)
                                                     name:@"didLoadEpgChannel"
                                                   object:self.channel];
    } else {
        [self.channel setDelegate:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"rqdMediaTVHChannelStoreProgramsCell" bundle:nil] forCellReuseIdentifier:@"ProgramListTableItems"];
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    
    [self initDelegate];
    [self.channel downloadRestOfEpg];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"EEE";
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HH:mm";
    
//    if ( DEVICE_HAS_IOS7 ) {
//        [self.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Play", @"toolbar play")];
//    } else {
//        factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
//        factory.size = 16;
//        [self.navigationItem.rightBarButtonItem setImage:[factory createImageForIcon:NIKFontAwesomeIconFilm]];
//    }
    [self.navigationItem.rightBarButtonItem setAccessibilityLabel:NSLocalizedString(@"Play Channel", @"accessbility")];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Play", @"toolbar play") style:(UIBarButtonItemStylePlain) target:self action:@selector(playStream:)];
    [self.segmentedControl removeAllSegments];
    [self updateSegmentControl];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
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

- (void)viewWillDisappear:(BOOL)animated {
    //    [self.help dismissActionSheet];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setSegmentedControl:nil];
    [super viewDidUnload];
    self.channel = nil;
    dateFormatter = nil;
    timeFormatter = nil;
    //    self.help = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pullToRefreshViewShouldRefresh
{
    [self.channel resetChannelEpgStore];
    [self.tableView reloadData];
    [self.channel downloadRestOfEpg];
}

#pragma mark - Table view data source

- (void)handleSwipeFromRight:(UISwipeGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        NSInteger sel = [self.segmentedControl selectedSegmentIndex] -1;
        if (sel >= 0 ) {
            [self.segmentedControl setSelectedSegmentIndex:sel];
            [self.tableView reloadData];
        } else if (sel<0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)handleSwipeFromLeft:(UISwipeGestureRecognizer *)recognizer {
    if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        NSInteger sel = [self.segmentedControl selectedSegmentIndex] + 1;
        if (sel < [self.segmentedControl numberOfSegments] ) {
            [self.segmentedControl setSelectedSegmentIndex:sel];
            [self.tableView reloadData];
        }
    }
}

- (NSString*)stringFromDate:(NSDate*)date {
    NSString *dayString;
    
    if ( [date isYesterday] ) {
        dayString = NSLocalizedString(@"Yesterday", @"");
    } else if ( [date isToday] ) {
        dayString = NSLocalizedString(@"Today", @"");
        //} else if ( [date isTomorrow] ) {
        //    dayString = NSLocalizedString(@"Tomorrow", @"");
    } else {
        dayString = [dateFormatter stringFromDate:date];
    }
    
    return dayString;
}

- (void)updateSegmentControl {
    if ( [self.channel countEpg] == 0 ) {
        self.segmentedControl.enabled = NO;
        return;
    } else {
        self.segmentedControl.enabled = YES;
    }
    
    for (int i=0 ; i<[self.channel totalCountOfDaysEpg]; i++) {
        NSDate *date = [self.channel dateForDay:i];
        if ( !date ) {
            // uh oh, so we don't have a date for this day? let's forcebly refresh
            NSLog(@"[Program Detail] - I don't have a date for the first epg program - bug?");
            return [self pullToRefreshViewShouldRefresh];
        }
        NSString *dateString = [self stringFromDate:date];
        if ( i >= [self.segmentedControl numberOfSegments] ) {
            [self.segmentedControl insertSegmentWithTitle:dateString atIndex:i animated:YES];
        } else {
            if ( ! [[self.segmentedControl titleForSegmentAtIndex:i] isEqualToString:dateString] ) {
                [self.segmentedControl setTitle:dateString forSegmentAtIndex:i];
            }
        }
    }
    
    // remove excess segments
    for ( NSInteger i = [self.segmentedControl numberOfSegments]; i > [self.channel totalCountOfDaysEpg]; i-- ) {
        [self.segmentedControl removeSegmentAtIndex:i animated:YES];
    }
    
    if ( self.segmentedControl.selectedSegmentIndex == -1 && [self.segmentedControl numberOfSegments] > 0 ) {
        [self.segmentedControl setSelectedSegmentIndex:0];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger selected = self.segmentedControl.selectedSegmentIndex;
    if ( self.segmentedControl.selectedSegmentIndex == -1 ) {
        selected = 0;
    }
    return [self.channel numberOfProgramsInDay:selected];
}

- (void)setScheduledIcon:(UIImageView*)schedStatusIcon forEpg:(TVHEpg*)epg {
    factory.size = 12;
    factory.colors = @[[UIColor grayColor], [UIColor lightGrayColor]];
    [schedStatusIcon setImage:nil];
    if ( [epg isScheduledForRecording] ) {
        [schedStatusIcon setImage:[factory createImageForIcon:NIKFontAwesomeIconClockO]];
    }
    if ( [epg isRecording] ) {
        factory.colors = @[[UIColor redColor]];
        [schedStatusIcon setImage:[factory createImageForIcon:NIKFontAwesomeIconBullseye]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProgramListTableItems" forIndexPath:indexPath];
    
    TVHEpg *epg = [self.channel programDetailForDay:self.segmentedControl.selectedSegmentIndex index:indexPath.row];
    
    UILabel *name = (UILabel *)[cell viewWithTag:100];
    UILabel *description = (UILabel *)[cell viewWithTag:101];
    UILabel *hour = (UILabel *)[cell viewWithTag:102];
    UIImageView *schedStatusImage = (UIImageView *)[cell viewWithTag:104];
    TVHProgressBar *progress = (TVHProgressBar *)[cell viewWithTag:105];
    
    hour.text = [timeFormatter stringFromDate: epg.start];
    name.text = epg.fullTitle;
    description.text = epg.description;
    if( [description.text isEqualToString:@""] ) {
        description.text = NSLocalizedString(@"Not Available", nil);;
    }
    [progress setHidden:YES];
    
    if( epg == self.channel.currentPlayingProgram ) {
        CGRect progressBarFrame = {
            .origin.x = progress.frame.origin.x,
            .origin.y = progress.frame.origin.y,
            .size.width = progress.frame.size.width,
            .size.height = 4,
        };
        [progress setFrame:progressBarFrame];
        progress.progress = epg.progress;
        progress.hidden = NO;
        
        if ( epg.progress < 0.9 ) {
            [progress setTintColor:PROGRESS_BAR_PLAYBACK];
        } else {
            [progress setTintColor:PROGRESS_BAR_NEAR_END_PLAYBACK];
        }
        
        // if it's recording, let's put the bar red =)
        if ( [epg isRecording] ) {
            [progress setTintColor:PROGRESS_BAR_RECORDING];
        }
    }
    
    [self setScheduledIcon:schedStatusImage forEpg:epg];
    
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", epg.fullTitle, [timeFormatter stringFromDate: epg.start]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if ( ! DEVICE_HAS_IOS7 ) {
        UIView *sepColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width , 1)];
        [sepColor setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]];
        [cell.contentView addSubview:sepColor];
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ( [self.channel countEpg] == 0 ) {
        return NSLocalizedString(@"EPG not available.",nil);
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TVHProgramDetailViewController *programDetailViewController=[[TVHProgramDetailViewController alloc]initWithNibName:@"TVHProgramDetailViewController" bundle:nil];//[[TVHProgramDetailViewController alloc]init];
    TVHEpg *epg = [self.channel programDetailForDay:self.segmentedControl.selectedSegmentIndex index:indexPath.row];
    [programDetailViewController setChannel:self.channel];
    [programDetailViewController setEpg:epg];
    [programDetailViewController setTitle:epg.title];
    programDetailViewController.channels=self.channels;
    programDetailViewController.currentPlayChannel=self.currentPlayChannel;
    
    [self.navigationController pushViewController:programDetailViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)willLoadEpgChannel {
    [TVHStatusBar setStatusText:[@"Loading Channel Data..." stringByAppendingString:[self.channel name]] timeout:2.0 animated:YES];
}

- (void)didLoadEpgChannel {
    [TVHStatusBar clearStatusAnimated:YES];
    [self updateSegmentControl];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didErrorLoadingEpgChannel:(NSError*)error {
    [TVHShowNotice errorNoticeInView:self.view title:NSLocalizedString(@"Network Error",nil) message:error.localizedDescription];
    [self.refreshControl endRefreshing];
}

- (void)playStream:(UIBarButtonItem*)sender {
    self.medialist=[[VLCMediaList alloc] init];
    for (TVHChannel *channel in self.channels) {
        [self _openURLStringAndDismiss:[channel streamUrlWithTranscoding:NO withInternal:YES]];
    }
        [rqdMediaPlaybackController sharedInstance].currentPlayChannel=self.currentPlayChannel.row;
        [rqdMediaPlaybackController sharedInstance].channels=self.channels;
        [[rqdMediaPlaybackController sharedInstance] playMediaList:self.medialist firstIndex:self.currentPlayChannel.row subtitlesFilePath:nil];
}

#pragma mark - internals
- (void)_openURLStringAndDismiss:(NSString *)url
{
    
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString: [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    [self.medialist addMedia:media];
    
}

- (IBAction)segmentDidChange:(id)sender {
    [self.tableView reloadData];
}


@end
