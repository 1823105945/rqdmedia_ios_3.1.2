//
//  rqdMediaWatchMessage.m
//  rqdMedia for iOS
//
//  Created by Tobias Conradi on 02.05.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "rqdMediaWatchMessage.h"

NSString *const rqdMediaWatchMessageNameGetNowPlayingInfo = @"getNowPlayingInfo";
NSString *const rqdMediaWatchMessageNamePlayPause = @"playpause";
NSString *const rqdMediaWatchMessageNameSkipForward = @"skipForward";
NSString *const rqdMediaWatchMessageNameSkipBackward = @"skipBackward";
NSString *const rqdMediaWatchMessageNamePlayFile = @"playFile";
NSString *const rqdMediaWatchMessageNameSetVolume = @"setVolume";
NSString *const rqdMediaWatchMessageNameNotification = @"notification";
NSString *const rqdMediaWatchMessageNameRequestThumbnail = @"requestThumbnail";
NSString *const rqdMediaWatchMessageNameRequestDB = @"requestDB";

NSString *const rqdMediaWatchMessageKeyURIRepresentation = @"URIRepresentation";


static NSString *const rqdMediaWatchMessageNameKey = @"name";
static NSString *const rqdMediaWatchMessagePayloadKey = @"payload";

@implementation rqdMediaWatchMessage
@synthesize dictionaryRepresentation = _dictionaryRepresentation;

- (instancetype)initWithName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _payload = payload;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *name = dictionary[rqdMediaWatchMessageNameKey];
    id<NSObject> payloadObject = dictionary[rqdMediaWatchMessagePayloadKey];
    id payload = [self payloadFromPayloadObject:payloadObject];
    return [self initWithName:name payload:payload];
}

- (NSDictionary *)dictionaryRepresentation
{
    if (!_dictionaryRepresentation) {
        _dictionaryRepresentation = [self.class messageDictionaryForName:self.name payload:self.payload];
    }
    return _dictionaryRepresentation;
}

- (id)payloadFromPayloadObject:(id<NSObject>)payloadObject {
    id payload;
    if ([payloadObject isKindOfClass:[NSData class]]) {
        @try {
            payload = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)payloadObject];
        }
        @catch (NSException *exception) {
            NSLog(@"%s Failed to decode payload with exception: %@",__PRETTY_FUNCTION__,exception);
        }
    } else {
        payload = payloadObject;
    }
    return payload;
}

+ (NSDictionary *)messageDictionaryForName:(NSString *)name payload:(nullable id<NSObject,NSCoding>)payload
{
    id payloadObject;
    BOOL noArchiving = [payload isKindOfClass:[NSNumber class]] || [payload isKindOfClass:[NSString class]];
    if (noArchiving) {
        payloadObject = payload;
    } else if (payload != nil) {
        payloadObject = [NSKeyedArchiver archivedDataWithRootObject:payload];
    }
    // we use nil termination so when payloadData is nil payload is not set
    return [NSDictionary dictionaryWithObjectsAndKeys:
            name,rqdMediaWatchMessageNameKey,
            payloadObject, rqdMediaWatchMessagePayloadKey,
            nil];
}
+ (NSDictionary *)messageDictionaryForName:(NSString *)name
{
    return [self messageDictionaryForName:name payload:nil];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p name=%@, payload=%@>",NSStringFromClass(self.class), self, _name, _payload];
}

@end
