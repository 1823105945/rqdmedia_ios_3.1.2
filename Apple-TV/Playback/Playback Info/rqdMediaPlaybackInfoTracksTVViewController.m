/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlaybackInfoTracksTVViewController.h"
#import "rqdMediaPlaybackInfoTVCollectionViewCell.h"
#import "rqdMediaPlaybackInfoTVCollectionSectionTitleView.h"
#import "rqdMediaPlaybackInfoCollectionViewDataSource.h"
#import "rqdMediaPlaybackInfoSubtitlesFetcherViewController.h"

#define CONTENT_INSET 20.


@interface rqdMediaPlaybackInfoTracksDataSourceAudio : rqdMediaPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end
@interface rqdMediaPlaybackInfoTracksDataSourceSubtitle : rqdMediaPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end


@interface rqdMediaPlaybackInfoTracksTVViewController ()
@property (nonatomic) IBOutlet rqdMediaPlaybackInfoTracksDataSourceAudio *audioDataSource;
@property (nonatomic) IBOutlet rqdMediaPlaybackInfoTracksDataSourceSubtitle *subtitleDataSource;
@end


@implementation rqdMediaPlaybackInfoTracksTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"TRACK_SELECTION", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"rqdMediaPlaybackInfoTVCollectionViewCell" bundle:nil];
    NSString *identifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];
    [self.audioTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [self.subtitleTrackCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [rqdMediaPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.audioTrackCollectionView];
    [rqdMediaPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.subtitleTrackCollectionView];

    NSLocale *currentLocale = [NSLocale currentLocale];
    self.audioDataSource.title = [NSLocalizedString(@"AUDIO", nil) uppercaseStringWithLocale:currentLocale];
    self.audioDataSource.cellIdentifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];
    self.subtitleDataSource.title = [NSLocalizedString(@"SUBTITLES", nil) uppercaseStringWithLocale:currentLocale];
    self.subtitleDataSource.cellIdentifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];
    self.subtitleDataSource.parentViewController = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat prefferedHeight = MAX(self.audioTrackCollectionView.contentSize.height, self.subtitleTrackCollectionView.contentSize.height) + CONTENT_INSET;
    return CGSizeMake(CGRectGetWidth(self.view.bounds), prefferedHeight);
}

- (void)mediaPlayerChanged
{
    [self.audioTrackCollectionView reloadData];
    [self.subtitleTrackCollectionView reloadData];
}

- (void)downloadMoreSPU
{
    rqdMediaPlaybackInfoSubtitlesFetcherViewController *targetViewController = [[rqdMediaPlaybackInfoSubtitlesFetcherViewController alloc] initWithNibName:nil bundle:nil];
    targetViewController.title = NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    [self presentViewController:targetViewController
                       animated:YES
                     completion:nil];
}

@end

@implementation rqdMediaPlaybackInfoTracksDataSourceAudio
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[rqdMediaPlaybackController sharedInstance] numberOfAudioTracks] + 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackInfoTVCollectionViewCell *trackCell = (rqdMediaPlaybackInfoTVCollectionViewCell*)cell;
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    NSString *trackName;

    trackCell.titleLabel.font = [UIFont systemFontOfSize:29.];

    if (row >= [vpc numberOfAudioTracks]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:krqdMediaSettingUseSPDIF]) {
            trackName = [@"✓ " stringByAppendingString:NSLocalizedString(@"USE_SPDIF", nil)];
            trackCell.titleLabel.font = [UIFont boldSystemFontOfSize:29.];
        } else
            trackName = NSLocalizedString(@"USE_SPDIF", nil);
    } else {
        BOOL isSelected = row == [vpc indexOfCurrentAudioTrack];
        trackCell.selectionMarkerVisible = isSelected;
        if (isSelected) {
            trackCell.titleLabel.font = [UIFont boldSystemFontOfSize:29.];
        }

        trackName = [vpc audioTrackNameAtIndex:row];
        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"])
                trackName = NSLocalizedString(@"DISABLE_LABEL", nil);
        }
    }
    trackCell.titleLabel.text = trackName;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    if (row >= [vpc numberOfAudioTracks]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL bValue = ![defaults boolForKey:krqdMediaSettingUseSPDIF];
        [vpc setAudioPassthrough:bValue];

        [defaults setBool:bValue forKey:krqdMediaSettingUseSPDIF];
    } else {
        [vpc selectAudioTrackAtIndex:row];
    }
    [collectionView reloadData];
}

@end

@implementation rqdMediaPlaybackInfoTracksDataSourceSubtitle
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[rqdMediaPlaybackController sharedInstance] numberOfVideoSubtitlesIndexes] + 1;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackInfoTVCollectionViewCell *trackCell = (rqdMediaPlaybackInfoTVCollectionViewCell*)cell;
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    NSString *trackName;
    if (row >= [vpc numberOfVideoSubtitlesIndexes]) {
        trackName = NSLocalizedString(@"DOWNLOAD_SUBS_FROM_OSO", nil);
    } else {
        BOOL isSelected = [vpc indexOfCurrentSubtitleTrack] == row;
        trackCell.selectionMarkerVisible = isSelected;

        trackName = [vpc videoSubtitleNameAtIndex:row];
        if (trackName != nil) {
            if ([trackName isEqualToString:@"Disable"])
                trackName = NSLocalizedString(@"DISABLE_LABEL", nil);
        }
    }
    trackCell.titleLabel.text = trackName;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSInteger row = indexPath.row;
    if (row >= [vpc numberOfVideoSubtitlesIndexes]) {
        if (self.parentViewController) {
            if ([self.parentViewController respondsToSelector:@selector(downloadMoreSPU)]) {
                [self.parentViewController performSelector:@selector(downloadMoreSPU)];
            }
        }
    } else {
        [vpc selectVideoSubtitleAtIndex:row];
        [collectionView reloadData];
    }
}

@end
