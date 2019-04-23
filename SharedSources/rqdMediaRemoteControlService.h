/*****************************************************************************
 * rqdMediaRemoteControlService.h
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class rqdMediaRemoteControlService;

@protocol rqdMediaRemoteControlServiceDelegate

- (void)remoteControlServiceHitPlay:(rqdMediaRemoteControlService *)rcs;
- (void)remoteControlServiceHitPause:(rqdMediaRemoteControlService *)rcs;
- (void)remoteControlServiceTogglePlayPause:(rqdMediaRemoteControlService *)rcs;
- (void)remoteControlServiceHitStop:(rqdMediaRemoteControlService *)rcs;
- (BOOL)remoteControlServiceHitPlayNextIfPossible:(rqdMediaRemoteControlService *)rcs;
- (BOOL)remoteControlServiceHitPlayPreviousIfPossible:(rqdMediaRemoteControlService *)rcs;
- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs jumpForwardInSeconds:(NSTimeInterval)seconds;
- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs jumpBackwardInSeconds:(NSTimeInterval)seconds;
- (NSInteger)remoteControlServiceNumberOfMediaItemsinList:(rqdMediaRemoteControlService *)rcs;
- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs setPlaybackRate:(CGFloat)playbackRate;
- (void)remoteControlService:(rqdMediaRemoteControlService *)rcs setCurrentPlaybackTime:(NSTimeInterval)playbackTime;

@end

@interface rqdMediaRemoteControlService : NSObject

@property (nonatomic, weak) id<rqdMediaRemoteControlServiceDelegate> remoteControlServiceDelegate;

- (void)subscribeToRemoteCommands;
- (void)unsubscribeFromRemoteCommands;

@end
