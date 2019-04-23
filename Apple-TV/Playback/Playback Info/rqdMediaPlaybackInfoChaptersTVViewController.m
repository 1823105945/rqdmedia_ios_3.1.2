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

#import "rqdMediaPlaybackInfoChaptersTVViewController.h"
#import "rqdMediaPlaybackInfoCollectionViewDataSource.h"
#import "rqdMediaPlaybackInfoTVCollectionViewCell.h"
#import "rqdMediaPlaybackInfoTVCollectionSectionTitleView.h"

#define CONTENT_INSET 20.
@interface rqdMediaPlaybackInfoTitlesDataSource : rqdMediaPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
// other collectionView which sould be updated when selection changes
@property (nonatomic) UICollectionView *dependendCollectionView;
@end

@interface rqdMediaPlaybackInfoChaptersTVViewController ()
@property (nonatomic) IBOutlet rqdMediaPlaybackInfoTitlesDataSource *titlesDataSource;
@property (nonatomic) IBOutlet rqdMediaPlaybackInfoCollectionViewDataSource *chaptersDataSource;
@end

@implementation rqdMediaPlaybackInfoChaptersTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"CHAPTER_SELECTION_TITLE", nil);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"rqdMediaPlaybackInfoTVCollectionViewCell" bundle:nil];
    NSString *identifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];

    [self.titlesCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [rqdMediaPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.titlesCollectionView];

    [self.chaptersCollectionView registerNib:nib forCellWithReuseIdentifier:identifier];
    [rqdMediaPlaybackInfoTVCollectionSectionTitleView registerInCollectionView:self.chaptersCollectionView];

    NSLocale *currentLocale = [NSLocale currentLocale];

    self.titlesDataSource.title = [NSLocalizedString(@"TITLE", nil) uppercaseStringWithLocale:currentLocale];
    self.titlesDataSource.cellIdentifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];
    self.chaptersDataSource.title = [NSLocalizedString(@"CHAPTER", nil) uppercaseStringWithLocale:currentLocale];
    self.chaptersDataSource.cellIdentifier = [rqdMediaPlaybackInfoTVCollectionViewCell identifier];

    self.titlesDataSource.dependendCollectionView = self.chaptersCollectionView;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaPlayerChanged) name:rqdMediaPlaybackControllerPlaybackMetadataDidChange object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)shouldBeVisibleForPlaybackController:(rqdMediaPlaybackController *)vpc
{
    return [vpc numberOfChaptersForCurrentTitle] > 1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mediaPlayerChanged];
}

- (CGSize)preferredContentSize
{
    CGFloat prefferedHeight = MAX(self.titlesCollectionView.contentSize.height, self.chaptersCollectionView.contentSize.height) + CONTENT_INSET;
    return CGSizeMake(CGRectGetWidth(self.view.bounds), prefferedHeight);
}

- (void)mediaPlayerChanged
{
    [self.titlesCollectionView reloadData];
    [self.chaptersCollectionView reloadData];
}

@end


@interface rqdMediaPlaybackInfoChaptersDataSource : rqdMediaPlaybackInfoCollectionViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate>
@end

@implementation rqdMediaPlaybackInfoTitlesDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[rqdMediaPlaybackController sharedInstance] numberOfTitles];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackInfoTVCollectionViewCell *trackCell = (rqdMediaPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];

    BOOL isSelected = [vpc indexOfCurrentTitle] == row;
    trackCell.selectionMarkerVisible = isSelected;

    NSDictionary *description = [vpc titleDescriptionsDictAtIndex:row];
    NSString *title = description[VLCTitleDescriptionName];
    if (title == nil)
        title = [NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"TITLE", nil), row];
    NSString *titleName = [NSString stringWithFormat:@"%@ (%@)", title, [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = titleName;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[rqdMediaPlaybackController sharedInstance] selectTitleAtIndex:indexPath.row];
    [collectionView reloadData];
    [self.dependendCollectionView reloadData];
}
@end

@implementation rqdMediaPlaybackInfoChaptersDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[rqdMediaPlaybackController sharedInstance] numberOfChaptersForCurrentTitle];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaPlaybackInfoTVCollectionViewCell *trackCell = (rqdMediaPlaybackInfoTVCollectionViewCell*)cell;
    NSInteger row = indexPath.row;

    BOOL isSelected = [[rqdMediaPlaybackController sharedInstance] indexOfCurrentChapter] == row;
    trackCell.selectionMarkerVisible = isSelected;

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSDictionary *description = [vpc chapterDescriptionsDictAtIndex:[vpc indexOfCurrentTitle]];

    NSString *chapter = description[VLCChapterDescriptionName];
    if (chapter == nil)
        chapter = [NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"CHAPTER", nil), row];
    NSString *chapterTitle = [NSString stringWithFormat:@"%@ (%@)", chapter, [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
    trackCell.titleLabel.text = chapterTitle;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[rqdMediaPlaybackController sharedInstance] selectChapterAtIndex:indexPath.row];
    [collectionView reloadData];
}

@end
