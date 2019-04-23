/*****************************************************************************
 * rqdMediaPlayerControlWebSocket.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaPlayerControlWebSocket.h"
#import "VLCMetadata.h"

@implementation rqdMediaPlayerControlWebSocket

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didOpen
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(playbackStarted)
                               name:rqdMediaPlaybackControllerPlaybackDidStart
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackStarted)
                               name:rqdMediaPlaybackControllerPlaybackDidResume
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(_respondToPlaying)
                               name:rqdMediaPlaybackControllerPlaybackMetadataDidChange
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackPaused)
                               name:rqdMediaPlaybackControllerPlaybackDidPause
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackEnded)
                               name:rqdMediaPlaybackControllerPlaybackDidStop
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackEnded)
                               name:rqdMediaPlaybackControllerPlaybackDidFail
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackSeekTo)
                               name:rqdMediaPlaybackControllerPlaybackPositionUpdated
                             object:nil];

    APLog(@"web socket did open");

    [super didOpen];
}

- (void)didReceiveMessage:(NSString *)msg
{
    NSError *error;
    NSDictionary *receivedDict = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];

    if (error != nil) {
        APLog(@"JSON deserialization failed for %@", msg);
        return;
    }

    NSString *type = receivedDict[@"type"];
    if (!type) {
        APLog(@"No type in received JSON dict %@", receivedDict);
    }

    if ([type isEqualToString:@"playing"]) {
        [self _respondToPlaying];
    } else if ([type isEqualToString:@"play"]) {
        [self _respondToPlay];
    } else if ([type isEqualToString:@"pause"]) {
        [self _respondToPause];
    } else if ([type isEqualToString:@"ended"]) {
        [self _respondToEnded];
    } else if ([type isEqualToString:@"seekTo"]) {
        [self _respondToSeek:receivedDict];
    } else if ([type isEqualToString:@"openURL"]) {
        [self performSelectorOnMainThread:@selector(_respondToOpenURL:) withObject:receivedDict waitUntilDone:NO];
    } else if ([type isEqualToString:@"volume"]) {
        [self sendMessage:@"VOLUME CONTROL NOT SUPPORTED ON THIS DEVICE"];
    } else
        [self sendMessage:@"INVALID REQUEST!"];
}

#ifndef NDEBUG
- (void)didClose
{
    APLog(@"web socket did close");

    [super didClose];
}
#endif

- (void)_respondToPlaying
{
    /* JSON response
     {
        "type": "playing",
        "currentTime": 42,
        "media": {
            "id": "some id",
            "title": "some title",
            "duration": 120000
        }
     }
     */

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSDictionary *returnDict;

    if (vpc.isPlaying) {
        VLCMedia *media = [vpc currentlyPlayingMedia];

        if (media) {
            NSURL *url = media.url;
            NSString *mediaTitle = vpc.metadata.title;
            if (!mediaTitle) {
                mediaTitle = url.lastPathComponent;
            }
            NSDictionary *mediaDict = @{ @"id" : url.absoluteString,
                                         @"title" : mediaTitle,
                                         @"duration" : @([vpc mediaDuration])};
            returnDict = @{ @"currentTime" : @([vpc playedTime].intValue),
                            @"type" : @"playing",
                            @"media" : mediaDict };
        }
    }
    if (!returnDict) {
        returnDict = [NSDictionary dictionary];
    }
    [self sendDataWithDict:returnDict];
}

#pragma mark - play

- (void)_respondToPlay
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    [vpc play];
}

- (void)playbackStarted
{
    /*
     {
        "type": "play",
        "currentTime": 42
     }
     */
     rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSDictionary *dict = @{ @"currentTime" : @([vpc playedTime].intValue),
                                  @"type" : @"play" };
    [self sendDataWithDict:dict];

}

#pragma mark - pause

- (void)_respondToPause
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    [vpc pause];
}

- (void)playbackPaused
{
    /*
     {
        "type": "pause",
        "currentTime": 42,
     }
     */
     rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    NSDictionary *dict = @{ @"currentTime" : @([vpc playedTime].intValue),
                            @"type" : @"pause" };
    [self sendDataWithDict:dict];
}

- (void)sendDataWithDict:(NSDictionary *)dict
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];

    VLCMedia *media = [vpc currentlyPlayingMedia];
    if (media) {
        NSError *error;
        NSData *returnData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if (error != nil) {
            APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
        }

        [self sendData:returnData];
    }
}

#pragma mark - ended

- (void)_respondToEnded
{
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    [vpc stopPlayback];
}

- (void)playbackEnded
{
    /*
     {
        "type": "ended"
     }
     */
    NSDictionary *dict = @{ @"type" : @"ended" };
    [self sendDataWithDict:dict];
}

#pragma mark - seek

- (void)_respondToSeek:(NSDictionary *)dictionary
{
    /*
     {
        "currentTime" = 12514;
        "type" = seekTo;
     }
     */
    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];

    VLCMedia *media = [vpc currentlyPlayingMedia];
    if (!media)
        return;

    vpc.playbackPosition = [dictionary[@"currentTime"] floatValue] / (CGFloat)media.length.intValue;
}

- (void)playbackSeekTo
{
    /* 
     {
        "type": "seekTo",
        "currentTime": 42,
        "media": {
            "id": 42
        }
     }
     */

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    VLCMedia *media = [vpc currentlyPlayingMedia];
    NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString};
    NSDictionary *dict = @{ @"currentTime" : @([vpc playedTime].intValue),
                                  @"type" : @"seekTo",
                                  @"media" : mediaDict };
    [self sendDataWithDict:dict];
}

#pragma mark - openURL
- (void)_respondToOpenURL:(NSDictionary *)dictionary
{
    /*
     {
        "type": "OpenURL",
        "url": "https://vimeo.com/74370512"
     }
     */
    BOOL needsMediaList = NO;

    rqdMediaPlaybackController *vpc = [rqdMediaPlaybackController sharedInstance];
    VLCMediaList *mediaList = vpc.mediaList;
    if (!mediaList) {
        needsMediaList = YES;
        mediaList = [[VLCMediaList alloc] init];
    }

    NSString *urlString = dictionary[@"url"];
    if (urlString == nil || urlString.length == 0)
        return;

    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    NSMutableArray *recentURLs = [NSMutableArray arrayWithArray:[ubiquitousKeyValueStore arrayForKey:krqdMediaRecentURLs]];

    /* re-order array and add item */
    if ([recentURLs indexOfObject:urlString] != NSNotFound)
        [recentURLs removeObject:urlString];

    if (recentURLs.count >= 100)
        [recentURLs removeLastObject];
    [recentURLs addObject:urlString];

    /* sync back */
    [ubiquitousKeyValueStore setArray:recentURLs forKey:krqdMediaRecentURLs];

    [mediaList addMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:urlString]]];
    if (needsMediaList) {
        [vpc playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];

        rqdMediaFullscreenMovieTVViewController *movieVC = [rqdMediaFullscreenMovieTVViewController fullscreenMovieTVViewController];
        if ([[[UIApplication sharedApplication].delegate.window rootViewController] presentedViewController] != nil) {
            [[[[UIApplication sharedApplication].delegate.window rootViewController] presentedViewController] presentViewController:movieVC
                                                                                                                           animated:NO
                                                                                                                         completion:nil];
        } else {
            [[[UIApplication sharedApplication].delegate.window rootViewController] presentViewController:movieVC
                                                                                                 animated:NO
                                                                                               completion:nil];
        }
    }
}

@end
