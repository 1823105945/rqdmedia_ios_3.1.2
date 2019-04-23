/*****************************************************************************
 * rqdMediaNetworkServerBrowserPlex.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaNetworkServerBrowserPlex.h"
#import "rqdMediaPlexParser.h"
#import "rqdMediaPlexWebAPI.h"

@interface rqdMediaNetworkServerBrowserPlex ()
@property (nonatomic, readonly) NSString *addressOrName;
@property (nonatomic, readonly) NSUInteger port;

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readonly) NSString *plexServerAddress;
@property (nonatomic, readonly) NSNumber *plexServerPort;
@property (nonatomic, readonly) NSString *plexServerPath;

@property (nonatomic) NSString *plexAuthentification;

@property (nonatomic, readonly) rqdMediaPlexParser *plexParser;
@property (nonatomic, readonly) rqdMediaPlexWebAPI *plexWebAPI;

@property (nonatomic, readonly) NSOperationQueue *plexQueue;

@property (nonatomic, readwrite) NSArray<id<rqdMediaNetworkServerBrowserItem>> *items;
@end

@implementation rqdMediaNetworkServerBrowserPlex
@synthesize title = _title, delegate = _delegate, items = _items, mediaList = _mediaList;

- (instancetype)initWithLogin:(rqdMediaNetworkServerLoginInformation *)login
{
    return [self initWithName:login.address
                         host:login.address
                   portNumber:login.port
                         path:@""
           authentificication:@""];
}

- (instancetype)initWithName:(NSString *)name host:(NSString *)addressOrName portNumber:(NSNumber *)portNumber path:(NSString *)path authentificication:(NSString *)auth
{
    self = [super init];
    if (self) {
        _title = name;
        _plexServerAddress = addressOrName;
        _plexServerPort = portNumber.intValue > 0 ? portNumber : @(32400);
        _plexServerPath = path;

        _plexAuthentification = auth;

        _plexParser = [[rqdMediaPlexParser alloc] init];
        _plexWebAPI = [[rqdMediaPlexWebAPI alloc] init];

        _plexQueue = [[NSOperationQueue alloc] init];
        _plexQueue.maxConcurrentOperationCount = 1;
        _plexQueue.name = @"org.videolan.rqdmedia-ios.plex.update";

        _items = [NSArray new];

    }
    return self;
}

- (instancetype)initWithName:(NSString *)name url:(NSURL *)url auth:(NSString *)auth {
    return [self initWithName:name host:url.host portNumber:url.port path:url.path authentificication:auth];
}

- (void)update {
    [self.plexQueue addOperationWithBlock:^{
        [self loadContents];
    }];
}

- (void)loadContents
{
    NSError *error = nil;
    NSArray *dicts = [self.plexParser PlexMediaServerParser:self.plexServerAddress port:self.plexServerPort navigationPath:self.plexServerPath authentification:self.plexAuthentification error:&error];

    if (error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate networkServerBrowser:self requestDidFailWithError:error];
        }];
        return;
    }

    NSDictionary *firstObject = [dicts firstObject];
    NSString *newAuth = firstObject[@"authentification"] ?: @"";

    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"http";
    components.host = self.plexServerAddress;
    components.port = self.plexServerPort;
    components.path = self.plexServerPath;
    NSURL *url = components.URL;

    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *dict in dicts) {
        rqdMediaNetworkServerBrowserItemPlex *item = [[rqdMediaNetworkServerBrowserItemPlex alloc] initWithDictionary:dict currentURL:url authentificication:newAuth];
        /* warning: we make a http request per item and if the library is big or a weak network, it can slow down the process. */
        if (item.URLcontainer) {
            NSArray *dictItem = [self.plexParser PlexMediaServerParser:self.plexServerAddress port:self.plexServerPort navigationPath:item.URLcontainer.path authentification:self.plexAuthentification error:&error];
            for (NSDictionary *dictx in dictItem) {
                item = [[rqdMediaNetworkServerBrowserItemPlex alloc] initWithDictionary:dictx currentURL:url authentificication:newAuth];
                [newItems addObject:item];
            }
        } else {
            [newItems addObject:item];
        }
    }

    NSString *titleValue = firstObject[@"libTitle"];
    if (titleValue.length) {
        self.title = titleValue;
    }
    self.plexAuthentification = newAuth;
    @synchronized(_items) {
        _items = [newItems copy];
    }
    _mediaList = [self buildMediaList];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.delegate networkServerBrowserDidUpdate:self];
    }];
}

- (VLCMediaList *)buildMediaList
{
    NSMutableArray *mediaArray;
    @synchronized(_items) {
        mediaArray = [NSMutableArray new];
        for (id<rqdMediaNetworkServerBrowserItem> browseritem in _items) {
            VLCMedia *media = [browseritem media];
            if (media)
                [mediaArray addObject:media];
        }
    }
    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:mediaArray];
    return mediaList;
}

- (NSString *)_urlAuth:(NSString *)url
{
    return [self.plexWebAPI urlAuth:url authentification:self.plexAuthentification];
}
@end


@interface rqdMediaNetworkServerBrowserItemPlex()

@property (nonatomic) NSString *plexAuthentification;
@end
@implementation rqdMediaNetworkServerBrowserItemPlex
@synthesize name = _name, URL = _URL, fileSizeBytes = _fileSizeBytes, container = _container;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary currentURL:(NSURL *)currentURL authentificication:(NSString *)auth
{
    self = [super init];
    if (self) {

        _plexAuthentification = auth;
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:currentURL resolvingAgainstBaseURL:NO];

        NSString *path = components.path;
        components.path = nil;
        NSURL *baseURL = components.URL;

        _container = ![dictionary[@"container"] isEqualToString:@"item"];
        NSString *urlPath;
        if (_container) {
            NSString *keyPath = nil;
            NSString *keyValue = dictionary[@"key"];
            if ([keyValue rangeOfString:@"library"].location == NSNotFound)
                keyPath = [path stringByAppendingPathComponent:keyValue];
            else
                keyPath = keyValue;

            if (keyPath)
                urlPath = [baseURL URLByAppendingPathComponent:keyPath].absoluteString;

        } else {
            NSString *keyPath = nil;
            NSString *keyValue = dictionary[@"key"];
            if ([keyValue rangeOfString:@"library"].location == NSNotFound)
                keyPath = [path stringByAppendingPathComponent:keyValue];
            else
                keyPath = keyValue;

            if (keyPath)
                urlPath = [baseURL URLByAppendingPathComponent:keyPath].absoluteString;

            urlPath = [rqdMediaPlexWebAPI urlAuth:urlPath authentification:auth];
            _URLcontainer = [NSURL URLWithString:urlPath];

            urlPath = dictionary[@"keyMedia"];
        }

        urlPath = [rqdMediaPlexWebAPI urlAuth:urlPath authentification:auth];
        _URL = [NSURL URLWithString:urlPath];

        _name = dictionary[@"title"];
        NSString *thumbPath = dictionary[@"thumb"];
        if (thumbPath) {
            thumbPath = [rqdMediaPlexWebAPI urlAuth:thumbPath authentification:auth];
        }
        _thumbnailURL = thumbPath.length ? [NSURL URLWithString:thumbPath] : nil;

        _duration = dictionary[@"duration"];
        _fileSizeBytes = dictionary[@"size"];
        _filename = dictionary[@"namefile"];

        NSString *subtitleURLString = dictionary[@"keySubtitle"];
        if (subtitleURLString)
            subtitleURLString = [rqdMediaPlexWebAPI urlAuth:subtitleURLString authentification:auth];

        _subtitleURL = subtitleURLString.length ? [NSURL URLWithString:subtitleURLString] : nil;

        NSString *subType = dictionary[@"codecSubtitle"];
        _subtitleType = subType.length ? subType : nil;
    }
    return self;
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

    VLCMedia *media =  [VLCMedia mediaWithURL:_URL];
    NSString *title = self.name;
    if (title.length) {
        [media setMetadata:self.name forKey:VLCMetaInformationTitle];
    }
    return media;
}

- (id<rqdMediaNetworkServerBrowser>)containerBrowser {
    return [[rqdMediaNetworkServerBrowserPlex alloc] initWithName:self.name url:self.URL auth:self.plexAuthentification];
}

@end
