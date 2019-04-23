/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaRemoteBrowsingTVCell.h"
#import "rqdMediaMDFBrowsingArtworkProvider.h"

NSString *const rqdMediaRemoteBrowsingTVCellIdentifier = @"rqdMediaRemoteBrowsingTVCell";

@interface rqdMediaRemoteBrowsingTVCell ()
{
    rqdMediaMDFBrowsingArtworkProvider *_artworkProvider;
}
@property (nonatomic) IBOutlet NSLayoutConstraint *aspectRationConstraint;
@property (nonatomic) NSLayoutConstraint *titleThumbnailConstraint;

@end

@implementation rqdMediaRemoteBrowsingTVCell

@synthesize thumbnailURL = _thumbnailURL, isDirectory = _isDirectory, couldBeAudioOnlyMedia = _couldBeAudioOnlyMedia;

- (void)awakeFromNib
{
    [super awakeFromNib];
    _artworkProvider = [[rqdMediaMDFBrowsingArtworkProvider alloc] init];
    _artworkProvider.artworkReceiver = self;
    _titleThumbnailConstraint = [self.titleLabel.topAnchor constraintEqualToAnchor:self.thumbnailImageView.bottomAnchor constant:15];
    [self.contentView addConstraint:_titleThumbnailConstraint];

    [self prepareForReuse];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_artworkProvider reset];
    [self.thumbnailImageView cancelLoading];
    self.title = nil;
    self.subtitle = nil;
    self.downloadArtwork = NO;
}

- (void)setCouldBeAudioOnlyMedia:(BOOL)couldBeAudioOnlyMedia
{
    _artworkProvider.searchForAudioMetadata = _couldBeAudioOnlyMedia;
    if (_couldBeAudioOnlyMedia != couldBeAudioOnlyMedia) {
        [_artworkProvider reset];
    }
    _couldBeAudioOnlyMedia = couldBeAudioOnlyMedia;
}

- (void)setThumbnailURL:(NSURL *)thumbnailURL
{
    _thumbnailURL = thumbnailURL;
    if (_thumbnailURL) {
        [self.thumbnailImageView setImageWithURL:thumbnailURL];
    } else {
        NSString *searchString = self.title;
        if (searchString != nil && !_isDirectory && _downloadArtwork) {
            [_artworkProvider searchForArtworkForVideoRelatedString:searchString];
        }
    }
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    [self.thumbnailImageView setImage:thumbnailImage];
}

-(UIImage *)thumbnailImage
{
    return self.thumbnailImageView.image;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    if (title != nil && !_isDirectory && _downloadArtwork) {
        [_artworkProvider searchForArtworkForVideoRelatedString:title];
    }
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
    self.subtitleLabel.text = subtitle;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [coordinator addCoordinatedAnimations:^{
        CGAffineTransform transform = context.nextFocusedView != self ? CGAffineTransformIdentity : CGAffineTransformMakeScale(1.1, 1.1);
        self.titleLabel.transform = transform;
        self.subtitleLabel.transform = transform;
        self.titleThumbnailConstraint.constant = context.nextFocusedView != self ? 15 : 40;
    } completion:nil];
}

@end
