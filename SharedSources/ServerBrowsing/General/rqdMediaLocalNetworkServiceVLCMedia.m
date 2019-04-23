/*****************************************************************************
 * rqdMediaLocalNetworkServiceVLCMedia.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaLocalNetworkServiceVLCMedia.h"

@interface rqdMediaLocalNetworkServiceVLCMedia()
@property (nonatomic) VLCMedia *mediaItem;
@end

@implementation rqdMediaLocalNetworkServiceVLCMedia
@synthesize serviceName = _serviceName;
- (instancetype)initWithMediaItem:(VLCMedia *)mediaItem serviceName:(nonnull NSString *)serviceName
{
    self = [super init];
    if (self) {
        _mediaItem = mediaItem;
        _serviceName = serviceName;
    }
    return self;
}
- (NSString *)title {
    return [self.mediaItem metadataForKey:VLCMetaInformationTitle];
}
- (UIImage *)icon {
    return nil;
}
@end
