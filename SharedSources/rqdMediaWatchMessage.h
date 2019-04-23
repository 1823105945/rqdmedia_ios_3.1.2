//
//  rqdMediaWatchMessage.h
//  rqdMedia for iOS
//
//  Created by Tobias Conradi on 02.05.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const rqdMediaWatchMessageNameGetNowPlayingInfo;
extern NSString *const rqdMediaWatchMessageNamePlayPause;
extern NSString *const rqdMediaWatchMessageNameSkipForward;
extern NSString *const rqdMediaWatchMessageNameSkipBackward;
extern NSString *const rqdMediaWatchMessageNamePlayFile;
extern NSString *const rqdMediaWatchMessageNameSetVolume;
extern NSString *const rqdMediaWatchMessageNameNotification;
extern NSString *const rqdMediaWatchMessageNameRequestThumbnail;
extern NSString *const rqdMediaWatchMessageNameRequestDB;

extern NSString *const rqdMediaWatchMessageKeyURIRepresentation;

@interface rqdMediaWatchMessage : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, nullable) id<NSObject,NSCoding> payload;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

- (instancetype)initWithName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)messageDictionaryForName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload;
+ (NSDictionary *)messageDictionaryForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
