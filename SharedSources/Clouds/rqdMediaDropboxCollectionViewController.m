/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaDropboxCollectionViewController.h"
#import "rqdMediaDropboxController.h"
#import "UIDevice+rqdMedia.h"
#import "rqdMediaRemoteBrowsingTVCell.h"
#import "rqdMediaRemoteBrowsingTVCell+CloudStorage.h"

@interface rqdMediaDropboxCollectionViewController () <rqdMediaCloudStorageDelegate>
{
    rqdMediaDropboxController *_dropboxController;
    DBFILESMetadata *_selectedFile;
    NSArray *_mediaList;
}
@end

@implementation rqdMediaDropboxCollectionViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _dropboxController = [rqdMediaDropboxController sharedInstance];
    self.controller = _dropboxController;
    self.controller.delegate = self;

    self.title = @"Dropbox";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.controller = [rqdMediaDropboxController sharedInstance];
    self.controller.delegate = self;

    if (self.currentPath != nil) {
        NSString *lastPathComponent = self.currentPath.lastPathComponent;
        self.title = lastPathComponent.length > 0 ? lastPathComponent : @"Dropbox";
    }

    [self updateViewAfterSessionChange];
}

- (void)mediaListUpdated
{
    _mediaList = [self.controller.currentListFiles copy];
    [self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    rqdMediaRemoteBrowsingTVCell *cell = (rqdMediaRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:rqdMediaRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    NSUInteger index = indexPath.row;
    if (_mediaList) {
        if (index < _mediaList.count) {
            cell.dropboxFile = _mediaList[index];
        }
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _mediaList[indexPath.row];
    if (![_selectedFile isKindOfClass:[DBFILESFolderMetadata class]])
        [_dropboxController streamFile:_selectedFile currentNavigationController:self.navigationController];
    else {
        /* dive into subdirectory */
        NSString *futurePath = [self.currentPath stringByAppendingFormat:@"/%@", _selectedFile.name];
        [_dropboxController reset];
        rqdMediaDropboxCollectionViewController *targetViewController = [[rqdMediaDropboxCollectionViewController alloc] initWithNibName:@"rqdMediaRemoteBrowsingCollectionViewController" bundle:nil];
        targetViewController.currentPath = futurePath;
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
    _selectedFile = nil;
}

@end
