/*****************************************************************************
 * NSString+SupportedMedia.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "NSString+SupportedMedia.h"

@implementation NSString (SupportedMedia)

- (BOOL)isSupportedMediaFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedFileExtensions options:options].location != NSNotFound);
}

- (BOOL)isSupportedAudioMediaFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedAudioFileExtensions options:options].location != NSNotFound);
}

- (BOOL)isSupportedSubtitleFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedSubtitleFileExtensions options:options].location != NSNotFound);
}

- (BOOL)isSupportedPlaylistFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedPlaylistFileExtensions options:options].location != NSNotFound);
}

- (BOOL)isSupportedFormat
{
    NSUInteger options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    return ([self rangeOfString:kSupportedSubtitleFileExtensions options:options].location != NSNotFound) || ([self rangeOfString:kSupportedAudioFileExtensions options:options].location != NSNotFound) || ([self rangeOfString:kSupportedFileExtensions options:options].location != NSNotFound);
}

@end
