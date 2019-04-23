/*****************************************************************************
 * rqdMediaWatchCommunication.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "rqdMediaWatchCommunication.h"
#import "rqdMediaWatchMessage.h"
#import "rqdMediaPlaybackController+MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaLibraryKit/UIImage+MLKit.h>
#import <WatchKit/WatchKit.h>
#import "rqdMediaThumbnailsCache.h"

@interface rqdMediaWatchCommunication()
@property (nonatomic, strong) NSOperationQueue *thumbnailingQueue;

@end

@implementation rqdMediaWatchCommunication

+ (BOOL)isSupported {
    return @available(iOS 9, *) && [WCSession isSupported];
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        if ([rqdMediaWatchCommunication isSupported]) {
            WCSession *session = [WCSession defaultSession];
            session.delegate = self;
            [session activateSession];
            _thumbnailingQueue = [NSOperationQueue new];
            _thumbnailingQueue.name = @"org.videolan.rqdmedia.watch-thumbnailing";
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

static rqdMediaWatchCommunication *_singeltonInstance = nil;

+ (rqdMediaWatchCommunication *)sharedInstance
{
    @synchronized(self) {
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            _singeltonInstance = [[self alloc] init];
        });
    }
    return _singeltonInstance;
}

- (void)playFileFromWatch:(rqdMediaWatchMessage *)message
{
    NSManagedObject *managedObject = nil;
    NSString *uriString = (id)message.payload;
    if ([uriString isKindOfClass:[NSString class]]) {
        NSURL *uriRepresentation = [NSURL URLWithString:uriString];
        managedObject = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:uriRepresentation];
    }
    if (managedObject == nil) {
        APLog(@"%s file not found: %@",__PRETTY_FUNCTION__,message);
        return;
    }

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    [vpc playMediaLibraryObject:managedObject];
}

#pragma mark - WCSessionDelegate
- (NSDictionary *)handleMessage:(nonnull rqdMediaWatchMessage *)message {
    UIApplication *application = [UIApplication sharedApplication];
    /* dispatch background task */
    __block UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithName:nil
                                                                               expirationHandler:^{
                                                                                   [application endBackgroundTask:taskIdentifier];
                                                                                   taskIdentifier = UIBackgroundTaskInvalid;
                                                                               }];

    NSString *name = message.name;
    NSDictionary *responseDict = @{};
    if ([name isEqualToString:rqdMediaWatchMessageNameGetNowPlayingInfo]) {
        responseDict = [self nowPlayingResponseDict];
    } else if ([name isEqualToString:rqdMediaWatchMessageNamePlayPause]) {
        [[rqdMediaPlaybackController sharedInstance] playPause];
        responseDict = @{@"playing": @([rqdMediaPlaybackController sharedInstance].isPlaying)};
    } else if ([name isEqualToString:rqdMediaWatchMessageNameSkipForward]) {
        [[rqdMediaPlaybackController sharedInstance] next];
    } else if ([name isEqualToString:rqdMediaWatchMessageNameSkipBackward]) {
        [[rqdMediaPlaybackController sharedInstance] previous];
    } else if ([name isEqualToString:rqdMediaWatchMessageNamePlayFile]) {
        [self playFileFromWatch:message];
    } else if ([name isEqualToString:rqdMediaWatchMessageNameSetVolume]) {
        [self setVolumeFromWatch:message];
    } else if ([name isEqualToString:rqdMediaWatchMessageNameRequestThumbnail]) {
        [self requestThumnail:message];
    } else if([name isEqualToString:rqdMediaWatchMessageNameRequestDB]) {
        [self copyCoreDataToWatch];
    } else {
        APLog(@"Did not handle request from WatchKit Extension: %@",message);
    }
    return responseDict;
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)userInfo replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    rqdMediaWatchMessage *message = [[rqdMediaWatchMessage alloc] initWithDictionary:userInfo];
    NSDictionary *responseDict = [self handleMessage:message];
    replyHandler(responseDict);
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)messageDict {
    rqdMediaWatchMessage *message = [[rqdMediaWatchMessage alloc] initWithDictionary:messageDict];
    [self handleMessage:message];
}

- (void)sessionWatchStateDidChange:(WCSession *)session {

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    [center removeObserver:self name:MLFileThumbnailWasUpdated object:nil];

    if ([[WCSession defaultSession] isPaired] && [[WCSession defaultSession] isWatchAppInstalled]) {
        [center addObserver:self selector:@selector(savedManagedObjectContextNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
        [center addObserver:self selector:@selector(didUpdateThumbnail:) name:MLFileThumbnailWasUpdated object:nil];
    }
}

#pragma mark -

- (void)setVolumeFromWatch:(rqdMediaWatchMessage *)message
{
    NSNumber *volume = (id)message.payload;
    if ([volume isKindOfClass:[NSNumber class]]) {
        /*
         * Since WatchKit doesn't provide something like MPVolumeView we use deprecated API.
         * rdar://20783803 Feature Request: WatchKit equivalent for MPVolumeView
         */
        [MPMusicPlayerController applicationMusicPlayer].volume = volume.floatValue;
    }
}

- (NSDictionary *)nowPlayingResponseDict {
    NSMutableDictionary *response = [NSMutableDictionary new];
    NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    NSNumber *playbackTime = [[rqdMediaPlaybackController sharedInstance] playbackTime];
    if (playbackTime) {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(playbackTime.floatValue/1000);
    }
    if (nowPlayingInfo) {
        response[@"nowPlayingInfo"] = nowPlayingInfo;
    }
    VLCMedia *currentFile = [rqdMediaPlaybackController sharedInstance].currentlyPlayingMedia;
    MLFile *mediaFile = [MLFile fileForURL:currentFile.url].firstObject;
    NSString *URIString = mediaFile.objectID.URIRepresentation.absoluteString;
    if (URIString) {
        response[rqdMediaWatchMessageKeyURIRepresentation] = URIString;
    }

    response[@"volume"] = @([MPMusicPlayerController applicationMusicPlayer].volume);

    return response;
}

- (void)requestThumnail:(rqdMediaWatchMessage *)message {
    NSAssert([message.payload isKindOfClass:[NSDictionary class]], @"the payload needs to be an NSDictionary");
    if (![message.payload isKindOfClass:[NSDictionary class]]) return;

    NSDictionary *payload = (NSDictionary *)message.payload;
    NSString *uriString = payload[rqdMediaWatchMessageKeyURIRepresentation];
    NSURL *url = [NSURL URLWithString:uriString];
    NSManagedObject *object = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:url];
    if (object) {
        [self transferThumbnailForObject:object refreshCache:NO];
    }
}

#pragma mark - Notifications
- (void)startRelayingNotificationName:(nullable NSString *)name object:(nullable id)object {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relayNotification:) name:name object:object];
}
- (void)stopRelayingNotificationName:(nullable NSString *)name object:(nullable id)object {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:object];
}
- (void)relayNotification:(NSNotification *)notification {

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"name"] = notification.name;
    if (notification.userInfo) {
        payload[@"userInfo"] = notification.userInfo;
    }
    NSDictionary *dict = [rqdMediaWatchMessage messageDictionaryForName:rqdMediaWatchMessageNameNotification
                                                           payload:payload];
    if ([WCSession isSupported] && [[WCSession defaultSession] isWatchAppInstalled] && [[WCSession defaultSession] isReachable]) {
        [[WCSession defaultSession] sendMessage:dict replyHandler:nil errorHandler:nil];
    }
}

#pragma mark - Copy CoreData to Watch

- (void)savedManagedObjectContextNotification:(NSNotification *)notification {
    NSManagedObjectContext *moc = notification.object;
    if (moc.persistentStoreCoordinator == [[MLMediaLibrary sharedMediaLibrary] persistentStoreCoordinator]) {
        [self copyCoreDataToWatch];
    }
}

- (void)copyCoreDataToWatch {
    if (![[WCSession defaultSession] isPaired] || ![[WCSession defaultSession] isWatchAppInstalled]) return;

    MLMediaLibrary *library = [MLMediaLibrary sharedMediaLibrary];
    NSPersistentStoreCoordinator *libraryPSC = [library persistentStoreCoordinator];
    NSPersistentStore *persistentStore = [libraryPSC persistentStoreForURL:[library persistentStoreURL]];
    NSURL *tmpDirectoryURL = [[WCSession defaultSession] watchDirectoryURL];
    NSURL *tmpURL = [tmpDirectoryURL URLByAppendingPathComponent:persistentStore.URL.lastPathComponent];

    NSMutableDictionary *destOptions = [persistentStore.options mutableCopy] ?: [NSMutableDictionary new];
    destOptions[NSSQLitePragmasOption] = @{@"journal_mode": @"DELETE"};

    NSError *error;
    bool success = [libraryPSC replacePersistentStoreAtURL:tmpURL destinationOptions:destOptions withPersistentStoreFromURL:persistentStore.URL sourceOptions:persistentStore.options storeType:NSSQLiteStoreType error:&error];
    if (!success) {
        NSLog(@"%s failed to copy persistent store to tmp location for copy to watch with error %@",__PRETTY_FUNCTION__,error);
    }

    // cancel old transfers
    NSArray<WCSessionFileTransfer *> *outstandingtransfers = [[WCSession defaultSession] outstandingFileTransfers];
    [outstandingtransfers enumerateObjectsUsingBlock:^(WCSessionFileTransfer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.file.metadata[@"filetype"] isEqualToString:@"coredata"]) {
            [obj cancel];
        }
    }];

    NSDictionary *metadata = @{@"filetype":@"coredata"};
    [[WCSession defaultSession] transferFile:tmpURL metadata:metadata];
}

- (void)transferThumbnailForObject:(NSManagedObject *__nonnull)object refreshCache:(BOOL)refresh{

    if (![[WCSession defaultSession] isPaired] || ![[WCSession defaultSession] isWatchAppInstalled]) {
        return;
    }

    CGRect bounds = [WKInterfaceDevice currentDevice].screenBounds;
    CGFloat scale = [WKInterfaceDevice currentDevice].screenScale;
    [self.thumbnailingQueue addOperationWithBlock:^{
        UIImage *scaledImage = [rqdMediaThumbnailsCache thumbnailForManagedObject:object refreshCache:refresh toFitRect:bounds scale:scale shouldReplaceCache:NO];
        [self transferImage:scaledImage forObjectID:object.objectID];
    }];

}

- (void)didUpdateThumbnail:(NSNotification *)notification {
    NSManagedObject *object = notification.object;
    if(![object isKindOfClass:[NSManagedObject class]])
        return;
    [self transferThumbnailForObject:object refreshCache:YES];
}

- (void)transferImage:(UIImage *)image forObjectID:(NSManagedObjectID *)objectID {
    if (!image || ![[WCSession defaultSession] isPaired] || ![[WCSession defaultSession] isWatchAppInstalled]) {
        return;
    }

    NSString *imageName = [[NSUUID UUID] UUIDString];
    NSURL *tmpDirectoryURL = [[WCSession defaultSession] watchDirectoryURL];
    NSURL *tmpURL = [tmpDirectoryURL URLByAppendingPathComponent:imageName];

    NSData *data = UIImageJPEGRepresentation(image, 0.7);
    [data writeToURL:tmpURL atomically:YES];

    NSDictionary *metaData = @{@"filetype" : @"thumbnail",
                               rqdMediaWatchMessageKeyURIRepresentation : objectID.URIRepresentation.absoluteString};

    NSArray<WCSessionFileTransfer *> *outstandingtransfers = [[WCSession defaultSession] outstandingFileTransfers];
    [outstandingtransfers enumerateObjectsUsingBlock:^(WCSessionFileTransfer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.file.metadata isEqualToDictionary:metaData])
            [obj cancel];
    }];

    [[WCSession defaultSession] transferFile:tmpURL metadata:metaData];
}


@end
