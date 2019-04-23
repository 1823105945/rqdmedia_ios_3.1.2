/*****************************************************************************
 * rqdMediaNetworkServerBrowserSharedLibrary.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkServerBrowserSharedLibrary.h"
#import "rqdMediaSharedLibraryParser.h"

@interface rqdMediaNetworkServerBrowserSharedLibrary () <rqdMediaSharedLibraryParserDelegate>
@property (nonatomic, readonly) NSString *addressOrName;
@property (nonatomic, readonly) NSUInteger port;
@property (nonatomic, readonly) rqdMediaSharedLibraryParser *httpParser;

@end

@implementation rqdMediaNetworkServerBrowserSharedLibrary
@synthesize title = _title, delegate = _delegate, items = _items, mediaList = _mediaList;

- (instancetype)initWithName:(NSString *)name host:(NSString *)addressOrName portNumber:(NSUInteger)portNumber
{
    self = [super init];
    if (self) {
        _title = name;
        _addressOrName = addressOrName;
        _port = portNumber;
        _items = [NSArray array];
        _httpParser = [[rqdMediaSharedLibraryParser alloc] init];
        _httpParser.delegate = self;
    }
    return self;
}

- (void)update {
    [self.httpParser fetchDataFromServer:self.addressOrName port:self.port];
}

#pragma mark - Specifics


- (void)sharedLibraryDataProcessings:(NSArray *)result
{
    _title = [result.firstObject objectForKey:@"libTitle"];

    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *dict in result) {
        [items addObject:[[rqdMediaNetworkServerBrowserItemSharedLibrary alloc] initWithDictionary:dict]];
    }
    @synchronized(_items) {
        _items = [items copy];
    }

    _mediaList = [self buildMediaList];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate networkServerBrowserDidUpdate:self];

    }];
}

- (VLCMediaList *)buildMediaList
{
    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    @synchronized(_items) {
        for (id<rqdMediaNetworkServerBrowserItem> browseritem in _items) {
            VLCMedia *media = [browseritem media];
            if (media)
                [mediaList addMedia:media];
        }
    }
    return mediaList;
}

@end


@implementation rqdMediaNetworkServerBrowserItemSharedLibrary
@synthesize name = _name, URL = _URL, fileSizeBytes = _fileSizeBytes, container = _container;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _name = dictionary[@"title"];
        _fileSizeBytes = dictionary[@"size"];
        _duration = dictionary[@"duration"];
        NSString *subtitleURLString = dictionary[@"pathSubtitle"];
        if ([subtitleURLString isEqualToString:@"(null)"])
            subtitleURLString = nil;
        subtitleURLString = [subtitleURLString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet];
        _subtitleURL = subtitleURLString.length ? [NSURL URLWithString:subtitleURLString] : nil;
        _URL = [NSURL URLWithString:dictionary[@"pathfile"]];
        _container = NO;

        NSString *thumbURLString = dictionary[@"thumb"];
        _thumbnailURL = thumbURLString.length ? [NSURL URLWithString:thumbURLString] : nil;

    }
    return self;
}

- (id<rqdMediaNetworkServerBrowser>)containerBrowser
{
    return nil;
}

- (BOOL)isDownloadable
{
    //rqdMedia also needs an extension in the filename for this to work.
    return YES;
}

- (VLCMedia *)media
{
    if (!_URL)
        return [VLCMedia mediaAsNodeWithName:self.name];
    return [VLCMedia mediaWithURL:_URL];
}

@end
