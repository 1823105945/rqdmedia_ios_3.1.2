/*****************************************************************************
 * rqdMediaBoxCollectionViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaBoxCollectionViewController.h"
#import "rqdMediaBoxController.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import "rqdMediaPlaybackController.h"
#import "rqdMediaRemoteBrowsingTVCell+CloudStorage.h"

@interface rqdMediaBoxCollectionViewController () <rqdMediaCloudStorageDelegate, NSURLConnectionDataDelegate>
{
    BoxFile *_selectedFile;
    rqdMediaBoxController *_boxController;
    NSArray *_listOfFiles;
}
@end

@implementation rqdMediaBoxCollectionViewController

- (instancetype)initWithPath:(NSString *)path
{
    self = [super initWithNibName:@"rqdMediaRemoteBrowsingCollectionViewController" bundle:nil];

    if (self) {
        self.currentPath = path;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _boxController = [rqdMediaBoxController sharedInstance];
    self.controller = _boxController;
    self.controller.delegate = self;

    self.title = @"Box";

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidRefreshTokensNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _boxController = [rqdMediaBoxController sharedInstance];
    self.controller = _boxController;
    self.controller.delegate = self;

    if (!_listOfFiles || _listOfFiles.count == 0)
        [self requestInformationForCurrentPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController == nil) {
        [_boxController stopSession];
        [self.collectionView reloadData];
    }
}

- (void)mediaListUpdated
{
    _listOfFiles = [[rqdMediaBoxController sharedInstance].currentListFiles copy];
    [self.collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaRemoteBrowsingTVCell *cell = (rqdMediaRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:rqdMediaRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    NSUInteger index = indexPath.row;
    if (_listOfFiles) {
        if (index < _listOfFiles.count) {
            cell.boxFile = _listOfFiles[index];
        }
    }

    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _listOfFiles.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= _listOfFiles.count)
        return;

    _selectedFile = _listOfFiles[indexPath.row];
    if (![_selectedFile.type isEqualToString:@"folder"])
        [self streamFile:(BoxFile *)_selectedFile];
    else {
        /* dive into subdirectory */
        NSString *path = self.currentPath;
        if (![path isEqualToString:@""])
            path = [path stringByAppendingString:@"/"];
        path = [path stringByAppendingString:_selectedFile.modelID];

        rqdMediaBoxCollectionViewController *targetViewController = [[rqdMediaBoxCollectionViewController alloc] initWithPath:path];
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
}


- (void)streamFile:(BoxFile *)file
{
    /* the Box API requires us to set an HTTP header to get the actual URL:
     * curl -L https://api.box.com/2.0/files/FILE_ID/content -H "Authorization: Bearer ACCESS_TOKEN"
     *
     * ... however, librqdmedia does not support setting custom HTTP headers, so we are resolving the redirect ourselves with a NSURLConnection
     * and pass the final location to librqdmedia, which does not require a custom HTTP header */

    NSURL *baseURL = [[[BoxSDK sharedSDK] filesManager] URLWithResource:@"files"
                                                                     ID:file.modelID
                                                            subresource:@"content"
                                                                  subID:nil];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:baseURL
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:60];

    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", [BoxSDK sharedSDK].OAuth2Session.accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLConnection *theTestConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [theTestConnection start];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {
        /* we have 1 redirect from the original URL, so as soon as we'd do that,
         * we grab the URL and cancel the connection */
        NSURL *theActualURL = request.URL;

        [connection cancel];

        /* now ask rqdMedia to stream the URL we were just passed */
        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:theActualURL]];
        [[rqdMediaPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];

        rqdMediaFullscreenMovieTVViewController *movieVC = [rqdMediaFullscreenMovieTVViewController fullscreenMovieTVViewController];
        [self presentViewController:movieVC
                           animated:YES
                         completion:nil];
    }

    return request;
}

#pragma mark - BoxAuthorizationViewControllerDelegate

- (void)boxApiTokenDidRefresh
{
    NSString *token = [BoxSDK sharedSDK].OAuth2Session.refreshToken;
    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = krqdMediaBoxService;
    keychainItem.account = krqdMediaBoxAccount;
    keychainItem.secret.stringValue = token;
    [keychainItem saveWithError:nil];

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:token forKey:krqdMediaStoreBoxCredentials];
    [ubiquitousStore synchronize];
    self.authorizationInProgress = YES;
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_boxController.hasMoreFiles && !self.activityIndicator.isAnimating) {
        [self requestInformationForCurrentPath];
    }
}

@end
