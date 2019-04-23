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

#import "rqdMediaRemoteBrowsingCollectionViewController.h"
#import "rqdMediaRemoteBrowsingTVCell.h"
#import "rqdMediaPlayerDisplayController.h"
#import "rqdMediaPlaybackController.h"
#import "rqdMediaServerBrowsingController.h"
#import "rqdMediaMaskView.h"

@implementation rqdMediaRemoteBrowsingCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    const CGFloat inset = 50;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    [self.collectionView registerNib:[UINib nibWithNibName:@"rqdMediaRemoteBrowsingTVCell" bundle:nil]
          forCellWithReuseIdentifier:rqdMediaRemoteBrowsingTVCellIdentifier];

    self.collectionView.maskView = [[rqdMediaMaskView alloc] initWithFrame:self.collectionView.bounds];

    /* After day 354 of the year, the usual rqdMedia cone is replaced by another cone
     * wearing a Father Xmas hat.
     * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
     * and should not be confused with the idea of religious statements or propagation there off
     */
    NSCalendar *gregorian =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate date]];
    if (dayOfYear >= 354)
        self.nothingFoundConeImageView.image = [UIImage imageNamed:@"xmas-cone"];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UICollectionView *collectionView = self.collectionView;
    rqdMediaMaskView *maskView = (rqdMediaMaskView *)collectionView.maskView;
    maskView.maskEnd = self.topLayoutGuide.length * 0.8;

    /*
     Update the position from where the collection view's content should
     start to fade out. The size of the fade increases as the collection
     view scrolls to a maximum of half the navigation bar's height.
     */
    CGFloat maximumMaskStart = maskView.maskEnd + (self.topLayoutGuide.length * 0.5);
    CGFloat verticalScrollPosition = MAX(0, collectionView.contentOffset.y + collectionView.contentInset.top);
    maskView.maskStart = MIN(maximumMaskStart, maskView.maskEnd + verticalScrollPosition);

    /*
     Position the mask view so that it is always fills the visible area of
     the collection view.
     */
    CGSize collectionViewSize = self.collectionView.bounds.size;
    maskView.frame = CGRectMake(0, collectionView.contentOffset.y, collectionViewSize.width, collectionViewSize.height);    
}


#pragma mark - collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaRemoteBrowsingTVCell *cell = (rqdMediaRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:rqdMediaRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];
    return cell;
}

@end
