//
//  TVHChannelStoreViewController.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/2/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHChannelStoreViewController.h"
#import "TVHChannelStoreProgramsViewController.h"
#import "TVHChannel.h"
#import "TVHShowNotice.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "TVHImageCache.h"
#import "TVHSettings.h"
#import "TVHSingletonServer.h"
#import "TVHProgressBar.h"
#import "Header.h"
#import "TVChannelListTableItems.h"
#import "VLCPlaybackController.h"
//#import "rqdMediaMovieViewController.h"


static NSString *ChannelListTableItems=@"ChannelListTableItems";
@interface TVHChannelStoreViewController () {
    NSDateFormatter *dateFormatter;
}
@property (weak, nonatomic) id <TVHChannelStore> channelStore;
@property (strong, nonatomic) NSArray *channels;
@property(strong,nonatomic)VLCMediaList *medialist;
//@property(nonatomic,strong)rqdMediaMovieViewController *movieViewController;
@end

@implementation TVHChannelStoreViewController 

// if we're called from tagstore, we'll set the filter of the channelStore to only get channels from the selected tag
- (NSString*)filterTagId {
    if( ! _filterTagId ) {
        return @"0";
    }
    return _filterTagId;
}

- (id <TVHChannelStore>)channelList {
    if ( _channelStore == nil) {
        _channelStore = [[TVHSingletonServer sharedServerInstance] channelStore];
    }
    return _channelStore;
}

- (void)viewDidAppear:(BOOL)animated
{
    [TVHAnalytics sendView:NSStringFromClass([self class])];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.tableView);
    [super viewDidAppear:animated];
}

- (void)initDelegate {
    if( [self.channelList delegate] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didLoadChannels)
                                                     name:TVHChannelStoreDidLoadNotification
                                                   object:self.channelList];
    } else {
        [self.channelList setDelegate:self];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetControllerData)
                                                 name:TVHWillDestroyServerNotification
                                               object:nil];

    [self.channelList setFilterTag:self.filterTagId];
    
    //pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefreshViewShouldRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView registerNib:[UINib nibWithNibName:@"TVChannelListTableItems" bundle:nil] forCellReuseIdentifier:ChannelListTableItems];
    self.tableView.tableFooterView=[UIView new];
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm";
    [self didLoadChannels];
    
}

- (void)viewDidUnload {
    self.channelStore = nil;
    self.channels = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetControllerData
{
    if ( self.splitViewController ) {
        UINavigationController *detailView = [self.splitViewController.viewControllers lastObject];
        [detailView popToRootViewControllerAnimated:NO];
        
        UINavigationController *mainView = [self.splitViewController.viewControllers firstObject];
        [mainView popToRootViewControllerAnimated:NO];
    }
}

- (void)pullToRefreshViewShouldRefresh
{
    [self.channelList fetchChannelList];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.channels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TVChannelListTableItems *cell = [tableView dequeueReusableCellWithIdentifier:@"ChannelListTableItems" forIndexPath:indexPath];    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TVHChannel *channel = [self.channels objectAtIndex:indexPath.row];
    NSArray *currentAndNextPlayingPrograms = [channel nextPrograms:3];
    
    UILabel *channelNameLabel = (UILabel *)[cell viewWithTag:100];
	UILabel *currentProgramLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *nextProgramLabel = (UILabel *)[cell viewWithTag:110];
    UILabel *laterProgramLabel = (UILabel *)[cell viewWithTag:111];
	__weak UIImageView *channelImage = (UIImageView *)[cell viewWithTag:102];
    TVHProgressBar *currentTimeProgress = (TVHProgressBar *)[cell viewWithTag:104];
    
    CGRect progressBarFrame = {
		.origin.x = currentTimeProgress.frame.origin.x,
		.origin.y = currentTimeProgress.frame.origin.y,
		.size.width = currentTimeProgress.frame.size.width,
		.size.height = 4,
	};
    [currentTimeProgress setFrame:progressBarFrame];
    
	currentProgramLabel.text = NSLocalizedString(@"Not Available", nil);
    nextProgramLabel.text = nil;
    laterProgramLabel.text = nil;
    currentTimeProgress.hidden = true;
    
    channelNameLabel.text = channel.name;
    channelImage.contentMode = UIViewContentModeScaleAspectFit;
    [channelImage sd_setImageWithURL:[NSURL URLWithString:channel.imageUrl] placeholderImage:[UIImage imageNamed:@"tv2.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!error && image) {
            channelImage.image = [TVHImageCache resizeImage:image];
            if ( channelImage.image.size.height > 0 /*&& cacheType == SDImageCacheTypeNone*/ ) {
                [TVHAnalytics sendEventWithCategory:@"images"
                                         withAction:@"ratio"
                                          withLabel:[NSString stringWithFormat:@"%.2f", (channelImage.image.size.width / channelImage.image.size.height)]
                                          withValue:@1];
            }
        }
    } ];
    
    
    if ( [[TVHSettings sharedInstance] useBlackBorders] ) {
        // rouding corners - this makes the animation in ipad become VERY SLOW!!!
        //channelImage.layer.cornerRadius = 2.0f;
        channelImage.layer.masksToBounds = NO;
        channelImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
        channelImage.layer.borderWidth = 0.4;
        channelImage.layer.shouldRasterize = YES;
    }
    
    if( [currentAndNextPlayingPrograms count] > 0 ) {
        TVHEpg *currentPlayingProgram = [currentAndNextPlayingPrograms objectAtIndex:0];
        NSString *time = [NSString stringWithFormat:@"%@ ", [dateFormatter stringFromDate:currentPlayingProgram.start]];
        currentProgramLabel.text = [time stringByAppendingString:[currentPlayingProgram fullTitle] ];
        if( [currentAndNextPlayingPrograms count] > 1 ) {
            TVHEpg *nextProgram = [currentAndNextPlayingPrograms objectAtIndex:1];
            NSString *time = [NSString stringWithFormat:@"%@ ", [dateFormatter stringFromDate:nextProgram.start]];
            nextProgramLabel.text = [time stringByAppendingString:[nextProgram fullTitle] ];
            
            // set red text for recording
            if( [nextProgram isScheduledForRecording] ) {
                nextProgramLabel.textColor = [UIColor redColor];
            } else {
                nextProgramLabel.textColor = [UIColor darkGrayColor];
            }
            
            if( [currentAndNextPlayingPrograms count] > 2 ) {
                TVHEpg *afterProgram = [currentAndNextPlayingPrograms objectAtIndex:2];
                NSString *time = [NSString stringWithFormat:@"%@ ", [dateFormatter stringFromDate:afterProgram.start]];
                laterProgramLabel.text = [time stringByAppendingString:[afterProgram fullTitle] ];
                
                // set red text for recording
                if( [afterProgram isScheduledForRecording] ) {
                    laterProgramLabel.textColor = [UIColor redColor];
                } else {
                    laterProgramLabel.textColor = [UIColor darkGrayColor];
                }
            }
        }
        
        //currentTimeProgramLabel.text = [NSString stringWithFormat:@"%@ | %@", [dateFormatter stringFromDate:currentPlayingProgram.start], [dateFormatter stringFromDate:currentPlayingProgram.end]];
        currentTimeProgress.hidden = false;
        float progress = [currentPlayingProgram progress];
        [currentTimeProgress setProgress:progress animated:NO];
        if ( progress < 0.9 ) {
            [currentTimeProgress setTintColor:PROGRESS_BAR_PLAYBACK];
        } else {
            [currentTimeProgress setTintColor:PROGRESS_BAR_NEAR_END_PLAYBACK];
        }
        
        // if it's recording, let's put the bar red =)
        if ( [currentPlayingProgram isRecording] ) {
            [currentTimeProgress setTintColor:PROGRESS_BAR_RECORDING];
        }
        
        cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@ %@ %@ %@", channel.name, currentPlayingProgram.title, [dateFormatter stringFromDate:currentPlayingProgram.start], NSLocalizedString(@"to",@"accessibility"), [dateFormatter stringFromDate:currentPlayingProgram.end] ];
    } else {
        cell.accessibilityLabel = channel.name;
    }
    
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

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self play:indexPath];
//    TVHChannelStoreProgramsViewController *channelStoreProgramsViewController=[[TVHChannelStoreProgramsViewController alloc]initWithNibName:@"TVHChannelStoreProgramsViewController" bundle:nil];
//    TVHChannel *channel = [self.channels objectAtIndex:indexPath.row];
//    channelStoreProgramsViewController.channels=self.channels;
//    channelStoreProgramsViewController.currentPlayChannel=indexPath;
//    [channelStoreProgramsViewController setChannel:channel];
//    [channelStoreProgramsViewController setTitle:channel.name];
//    [self.navigationController pushViewController:channelStoreProgramsViewController animated:YES];
}

-(void)play:(NSIndexPath *)row{
    self.medialist=[[VLCMediaList alloc] init];
    for (TVHChannel *channel in self.channels) {
        [self _openURLStringAndDismiss:[channel streamUrlWithTranscoding:NO withInternal:YES]];
    }
    [rqdMediaPlaybackController sharedInstance].currentPlayChannel=row.row;
    [rqdMediaPlaybackController sharedInstance].channels=self.channels;
    [[rqdMediaPlaybackController sharedInstance] playMediaList:self.medialist firstIndex:row.row subtitlesFilePath:nil];
}

#pragma mark - internals
- (void)_openURLStringAndDismiss:(NSString *)url
{
    
    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString: [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
    [self.medialist addMedia:media];
    
}

- (void)willLoadChannels {
    [TVHStatusBar setStatusText:@"Loading Channels..." timeout:2.0 animated:YES];
}

- (void)didLoadChannels {
    [TVHStatusBar clearStatusAnimated:YES];
    self.channels = [[self.channelStore arrayChannels] copy];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}



- (void)didErrorLoadingChannelStore:(NSError*)error; {
    [TVHShowNotice errorNoticeInView:self.view title:NSLocalizedString(@"Network Error", nil) message:error.localizedDescription];
    [self.refreshControl endRefreshing];
}



@end
