/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaSearchableServerBrowsingTVViewController.h"
#import "rqdMediaNetworkServerSearchBrowser.h"
#import "rqdMediaSearchController.h"

static NSString * const rqdMediaSearchableServerBrowsingTVViewControllerSectionHeaderKey = @"rqdMediaSearchableServerBrowsingTVViewControllerSectionHeader";
@interface rqdMediaSearchableServerBrowsingTVViewControllerHeader : UICollectionReusableView
@property (nonatomic) UISearchBar *searchBar;
@end

@interface rqdMediaSearchableServerBrowsingTVViewController() <UISearchControllerDelegate, UISearchResultsUpdating>
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) rqdMediaNetworkServerSearchBrowser *searchBrowser;
@end

@implementation rqdMediaSearchableServerBrowsingTVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    rqdMediaNetworkServerSearchBrowser *searchBrowser = [[rqdMediaNetworkServerSearchBrowser alloc] initWithServerBrowser:self.serverBrowser];
    rqdMediaServerBrowsingTVViewController *resultBrowsingViewController = [[rqdMediaServerBrowsingTVViewController alloc] initWithServerBrowser:searchBrowser];
    resultBrowsingViewController.subdirectoryBrowserClass = [self class];
    _searchBrowser = searchBrowser;
    UISearchController *searchController = [[rqdMediaSearchController alloc] initWithSearchResultsController:resultBrowsingViewController];
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController = searchController;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.headerReferenceSize = searchController.searchBar.bounds.size;

    [self.collectionView registerClass:[rqdMediaSearchableServerBrowsingTVViewControllerHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:rqdMediaSearchableServerBrowsingTVViewControllerSectionHeaderKey];
}

#pragma mark - UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:rqdMediaSearchableServerBrowsingTVViewControllerSectionHeaderKey forIndexPath:indexPath];

    rqdMediaSearchableServerBrowsingTVViewControllerHeader *header = [supplementaryView isKindOfClass:[rqdMediaSearchableServerBrowsingTVViewControllerHeader class]] ? (id)supplementaryView : nil;
    UISearchController *searchController = self.searchController;
    header.searchBar = searchController.searchBar;
    if (!searchController.active) {
        [header addSubview:searchController.searchBar];
    }
    return supplementaryView;
}

#pragma mark - rqdMediaNetworkServerBrowserDelegate
- (void)networkServerBrowserDidUpdate:(id<rqdMediaNetworkServerBrowser>)networkBrowser
{
    [super networkServerBrowserDidUpdate:networkBrowser];
    if (self.searchController.active) {
        [self.searchBrowser networkServerBrowserDidUpdate:networkBrowser];
    }
}

- (void)networkServerBrowser:(id<rqdMediaNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error
{
    if (self.searchController.active) {
        [self.searchBrowser networkServerBrowser:networkBrowser requestDidFailWithError:error];
    } else {
        [super networkServerBrowser:networkBrowser requestDidFailWithError:error];
    }
}

#pragma mark - UISearchControllerDelegate
- (void)willPresentSearchController:(UISearchController *)searchController
{
    [self.searchBrowser networkServerBrowserDidUpdate:self.serverBrowser];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.searchBrowser.searchText = searchController.searchBar.text;
}

@end

@implementation rqdMediaSearchableServerBrowsingTVViewControllerHeader

- (void)setSearchBar:(UISearchBar *)searchBar {
    _searchBar = searchBar;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // UISearchController 'steals' the search bar from us when it's active.
    if (self.searchBar.superview == self) {
        self.searchBar.center = self.center;
    }
}

@end
