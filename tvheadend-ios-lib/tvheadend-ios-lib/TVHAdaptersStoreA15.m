//
//  TVHAdaptersStore40.m
//  TvhClient
//
//  Created by Luis Fernandes on 05/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHAdaptersStoreA15.h"

@implementation TVHAdaptersStoreA15

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    return nil;
}

- (NSString*)apiMethod {
    return @"GET";
}

- (NSString*)apiPath {
    return @"api/status/inputs";
}

- (NSDictionary*)apiParameters {
    return nil;
}

@end
