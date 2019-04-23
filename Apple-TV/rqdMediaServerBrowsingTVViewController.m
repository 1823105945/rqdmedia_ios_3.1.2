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

#import "rqdMediaServerBrowsingTVViewController.h"
#import "rqdMediaRemoteBrowsingTVCell.h"
#import "rqdMediaPlayerDisplayController.h"
#import "rqdMediaPlaybackController.h"
#import "rqdMediaServerBrowsingController.h"
#import "rqdMediaMaskView.h"
#import "GRKArrayDiff+UICollectionView.h"

@interface rqdMediaServerBrowsingTVViewController ()
{
    UILabel *_nothingFoundLabel;
}
@property (nonatomic) rqdMediaServerBrowsingController *browsingController;
@property (nonatomic) NSArray<id <rqdMediaNetworkServerBrowserItem>> *items;
@end

@implementation rqdMediaServerBrowsingTVViewController
@synthesize subdirectoryBrowserClass = _subdirectoryBrowserClass;

- (instancetype)initWithServerBrowser:(id<rqdMediaNetworkServerBrowser>)serverBrowser
{
    self = [super initWithNibName:@"rqdMediaRemoteBrowsingCollectionViewController" bundle:nil];
    if (self) {
        _serverBrowser = serverBrowser;
        serverBrowser.delegate = self;

        _browsingController = [[rqdMediaServerBrowsingController alloc] initWithViewController:self serverBrowser:serverBrowser];

        self.title = serverBrowser.title;

        self.downloadArtwork = [[NSUserDefaults standardUserDefaults] boolForKey:krqdMediaSettingDownloadArtwork];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.nothingFoundLabel.text = NSLocalizedString(@"FOLDER_EMPTY", nil);
    [self.nothingFoundLabel sizeToFit];
    UIView *nothingFoundView = self.nothingFoundView;
    [nothingFoundView sizeToFit];
    [nothingFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:nothingFoundView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.serverBrowser update];
}

- (void)setSubdirectoryBrowserClass:(Class)subdirectoryBrowserClass
{
    NSParameterAssert([subdirectoryBrowserClass isSubclassOfClass:[rqdMediaServerBrowsingTVViewController class]]);
    _subdirectoryBrowserClass = subdirectoryBrowserClass;
}

- (Class)subdirectoryBrowserClass
{
    return _subdirectoryBrowserClass ?: [self class];
}

#pragma mark -

- (void)reloadData
{
    [self.serverBrowser update];
}

#pragma mark - rqdMediaNetworkServerBrowserDelegate

- (void)networkServerBrowserDidUpdate:(id<rqdMediaNetworkServerBrowser>)networkBrowser
{
    self.title = networkBrowser.title;

    NSArray *oldItems = self.items;
    NSArray *newItems = networkBrowser.items;
    GRKArrayDiff *diff = [[GRKArrayDiff alloc] initWithPreviousArray:oldItems
                                                        currentArray:newItems
                                                       identityBlock:^NSString * _Nullable(id <rqdMediaNetworkServerBrowserItem> item) {
                                                           return [NSString stringWithFormat:@"%@#%@",item.URL.absoluteString ?: @"", item.name];
                                                       }
                                                       modifiedBlock:nil];

    [diff performBatchUpdatesWithCollectionView:self.collectionView
                                        section:0
                               dataSourceUpdate:^{
                                   self.items = newItems;
                               } completion:nil];

    _nothingFoundLabel.hidden = self.items.count > 0;
}

- (void)networkServerBrowser:(id<rqdMediaNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error {

    [self rqdmedia_showAlertWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                         message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                     buttonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)];
}

#pragma mark -

- (void)didSelectItem:(id<rqdMediaNetworkServerBrowserItem>)item index:(NSUInteger)index singlePlayback:(BOOL)singlePlayback
{
    if (item.isContainer) {
        rqdMediaServerBrowsingTVViewController *targetViewController = [[self.subdirectoryBrowserClass alloc] initWithServerBrowser:item.containerBrowser];
        [self showViewController:targetViewController sender:self];
    } else {
        if (singlePlayback) {
            [self.browsingController streamFileForItem:item];
        } else {
            VLCMediaList *mediaList = self.serverBrowser.mediaList;
            [self.browsingController configureSubtitlesInMediaList:mediaList];
            [self.browsingController streamMediaList:mediaList startingAtIndex:index];
        }
    }
}


#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.items.count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = self.items;
    NSInteger row = indexPath.row;
    if (row < items.count) {
        id<rqdMediaNetworkServerBrowserItem> item = items[row];

        if ([cell isKindOfClass:[rqdMediaRemoteBrowsingTVCell class]]) {
            ((rqdMediaRemoteBrowsingTVCell *) cell).downloadArtwork = self.downloadArtwork;
        }

        if ([cell conformsToProtocol:@protocol(rqdMediaRemoteBrowsingCell)]) {
            [self.browsingController configureCell:(id<rqdMediaRemoteBrowsingCell>)cell withItem:item];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    id<rqdMediaNetworkServerBrowserItem> item = self.items[row];

    // would make sence if item came from search which isn't
    // currently the case on the TV
    const BOOL singlePlayback = ![[NSUserDefaults standardUserDefaults] boolForKey:krqdMediaAutomaticallyPlayNextItem];
    [self didSelectItem:item index:row singlePlayback:singlePlayback];
}

@end
