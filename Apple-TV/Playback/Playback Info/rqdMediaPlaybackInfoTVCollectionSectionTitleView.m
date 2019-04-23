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

#import "rqdMediaPlaybackInfoTVCollectionSectionTitleView.h"

@implementation rqdMediaPlaybackInfoTVCollectionSectionTitleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        if ([UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            label.textColor = [UIColor rqdMediaLightTextColor];
        } else {
            label.textColor = [UIColor rqdMediaDarkTextColor];
        }
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:label];
        _titleLabel = label;
    }
    return self;
}

+ (void)registerInCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerClass:self forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[self identifier]];
}

+ (NSString *)identifier
{
    return @"rqdMediaPlaybackInfoTVCollectionSectionTitleView";
}


@end
