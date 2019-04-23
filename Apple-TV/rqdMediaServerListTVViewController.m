/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaServerListTVViewController.h"
#import "rqdMediaSearchableServerBrowsingTVViewController.h"
#import "rqdMediaNetworkServerLoginInformation.h"

#import "rqdMediaNetworkServerBrowserPlex.h"
#import "rqdMediaNetworkServerBrowserVLCMedia.h"
#import "rqdMediaNetworkServerBrowserFTP.h"

#import "rqdMediaLocalNetworkServiceBrowserManualConnect.h"
#import "rqdMediaLocalNetworkServiceBrowserPlex.h"
#import "rqdMediaLocalNetworkServiceBrowserFTP.h"
#import "rqdMediaLocalNetworkServiceBrowserUPnP.h"
#ifndef NDEBUG
#import "rqdMediaLocalNetworkServiceBrowserSAP.h"
#endif
#import "rqdMediaLocalNetworkServiceBrowserDSM.h"
#import "rqdMediaLocalNetworkServiceBrowserBonjour.h"
#import "rqdMediaLocalNetworkServiceBrowserHTTP.h"

#import "rqdMediaNetworkServerLoginInformation+Keychain.h"

#import "rqdMediaRemoteBrowsingTVCell.h"
#import "GRKArrayDiff+UICollectionView.h"

@interface rqdMediaServerListTVViewController ()
{
    UILabel *_nothingFoundLabel;
}
@property (nonatomic, copy) NSMutableArray<id<rqdMediaLocalNetworkService>> *networkServices;

@end

@implementation rqdMediaServerListTVViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"rqdMediaRemoteBrowsingCollectionViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll ^ UIRectEdgeTop;

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(250.0, 300.0);
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 100.0;

    self.nothingFoundLabel.text = NSLocalizedString(@"NO_SERVER_FOUND", nil);
    [self.nothingFoundLabel sizeToFit];
    UIView *nothingFoundView = self.nothingFoundView;
    [nothingFoundView sizeToFit];
    [nothingFoundView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:nothingFoundView];

    NSLayoutConstraint *yConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:yConstraint];
    NSLayoutConstraint *xConstraint = [NSLayoutConstraint constraintWithItem:nothingFoundView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self.view addConstraint:xConstraint];

    NSArray *classes = @[
                         [rqdMediaLocalNetworkServiceBrowserHTTP class],
                         [rqdMediaLocalNetworkServiceBrowserUPnP class],
                         [rqdMediaLocalNetworkServiceBrowserDSM class],
                         [rqdMediaLocalNetworkServiceBrowserPlex class],
                         [rqdMediaLocalNetworkServiceBrowserFTP class],
#ifndef NDEBUG
                         [rqdMediaLocalNetworkServiceBrowserSAP class],
#endif
                         ];
    self.discoveryController = [[rqdMediaLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:classes];
    self.discoveryController.delegate = self;
}

- (NSString *)title {
    return NSLocalizedString(@"LOCAL_NETWORK", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.discoveryController startDiscovery];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.discoveryController stopDiscovery];
}

#pragma mark - Collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.networkServices.count;
    self.nothingFoundView.hidden = count > 0;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    rqdMediaRemoteBrowsingTVCell *browsingCell = (rqdMediaRemoteBrowsingTVCell *) [collectionView dequeueReusableCellWithReuseIdentifier:rqdMediaRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    id<rqdMediaLocalNetworkService> service = self.networkServices[indexPath.row];
    if (service == nil)
        return browsingCell;

    browsingCell.isDirectory = YES;
    browsingCell.title = service.title;
    browsingCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    browsingCell.subtitle = service.serviceName;
    browsingCell.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    UIImage *serviceIcon = service.icon;
    browsingCell.thumbnailImage = serviceIcon ? serviceIcon : [UIImage imageNamed:@"serverIcon"];

    return browsingCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<rqdMediaLocalNetworkService> service = self.networkServices[indexPath.row];
    [self didSelectService:service];
}

#pragma mark - Service specific stuff

- (void)didSelectService:(id<rqdMediaLocalNetworkService>)service
{
    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id <rqdMediaNetworkServerBrowser> browser = [service serverBrowser];
        if (browser) {
            rqdMediaServerBrowsingTVViewController *browsingViewController = [[rqdMediaSearchableServerBrowsingTVViewController alloc] initWithServerBrowser:browser];
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:browsingViewController]
                               animated:YES
                             completion:nil];
            return;
        }
    }

    if ([service respondsToSelector:@selector(loginInformation)]) {
        rqdMediaNetworkServerLoginInformation *login = service.loginInformation;
        if (!login) return;

        NSError *error = nil;
        if ([login loadLoginInformationFromKeychainWithError:&error])
        {
            [self showLoginAlertWithLogin:login];
        } else {
            [self showKeychainLoadError:error forLogin:login];
        }
        return;
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {

        NSURL *url = service.directPlaybackURL;
        if (!url) return;

        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:url]];

        [[rqdMediaPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];

        [self presentViewController:[rqdMediaFullscreenMovieTVViewController fullscreenMovieTVViewController]
                           animated:YES
                         completion:nil];
    }
}

- (void)showKeychainLoadError:(NSError *)error forLogin:(rqdMediaNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [self showLoginAlertWithLogin:login];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showKeychainSaveError:(NSError *)error forLogin:(rqdMediaNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)showKeychainDeleteError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                             message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)showLoginAlertWithLogin:(nonnull rqdMediaNetworkServerLoginInformation *)login
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONNECT_TO_SERVER", nil)
                                                                             message:login.address preferredStyle:UIAlertControllerStyleAlert];

    __block UITextField *usernameField = nil;
    __block UITextField *passwordField = nil;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"USER_LABEL", nil);
        textField.text = login.username;
        usernameField = textField;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = NSLocalizedString(@"PASSWORD_LABEL", nil);
        textField.text = login.password;
        passwordField = textField;
    }];

    NSMutableDictionary *additionalFieldsDict = [NSMutableDictionary dictionaryWithCapacity:login.additionalFields.count];
    for (rqdMediaNetworkServerLoginInformationField *fieldInfo in login.additionalFields) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            switch (fieldInfo.type) {
                case rqdMediaNetworkServerLoginInformationFieldTypeNumber:
                    textField.keyboardType = UIKeyboardTypeNumberPad;
                    break;
                case rqdMediaNetworkServerLoginInformationFieldTypeText:
                default:
                    textField.keyboardType = UIKeyboardTypeDefault;
                    break;
            }
            textField.placeholder = fieldInfo.localizedLabel;
            textField.text = fieldInfo.textValue;
            additionalFieldsDict[fieldInfo.identifier] = textField;
        }];
    }

    void(^loginBlock)(BOOL) = ^(BOOL save) {
        login.username = usernameField.text;
        login.password = passwordField.text;
        for (rqdMediaNetworkServerLoginInformationField *fieldInfo in login.additionalFields) {
            UITextField *textField = additionalFieldsDict[fieldInfo.identifier];
            fieldInfo.textValue = textField.text;
        }
        if (save) {
            NSError *error = nil;
            if (![login saveLoginInformationToKeychainWithError:&error]) {
                [self showKeychainSaveError:error forLogin:login];
            }
        }
        [self showBrowserWithLogin:login];
    };

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"LOGIN", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          loginBlock(NO);
                                                      }]];

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_SAVE", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          loginBlock(YES);
                                                      }]];
    if (login.username.length || login.password.length) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              NSError *error = nil;
                                                              if (![login deleteFromKeychainWithError:&error]){
                                                                  [self showKeychainDeleteError:error];
                                                              }
                                                          }]];
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_ANONYMOUS_LOGIN", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              login.username = nil;
                                                              login.password = nil;
                                                              [self showBrowserWithLogin:login];
                                                          }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showBrowserWithLogin:(nonnull rqdMediaNetworkServerLoginInformation *)login
{
    id<rqdMediaNetworkServerBrowser> serverBrowser = nil;
    NSString *identifier = login.protocolIdentifier;

    if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierFTP]) {
        serverBrowser = [[rqdMediaNetworkServerBrowserFTP alloc] initWithLogin:login];
    } else if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierPlex]) {
        serverBrowser = [[rqdMediaNetworkServerBrowserPlex alloc] initWithLogin:login];
    } else if ([identifier isEqualToString:rqdMediaNetworkServerProtocolIdentifierSMB]) {
        serverBrowser = [rqdMediaNetworkServerBrowserVLCMedia SMBNetworkServerBrowserWithLogin:login];
    }

    if (serverBrowser) {
        rqdMediaServerBrowsingTVViewController *targetViewController = [[rqdMediaSearchableServerBrowsingTVViewController alloc] initWithServerBrowser:serverBrowser];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:targetViewController]
                           animated:YES
                         completion:nil];
    }
}

#pragma mark - rqdMediaLocalServerDiscoveryController
- (void)discoveryFoundSomethingNew
{
    NSString * (^mapServiceName)(id<rqdMediaLocalNetworkService>) = ^NSString *(id<rqdMediaLocalNetworkService> service) {
        return [NSString stringWithFormat:@"%@: %@", service.serviceName, service.title];
    };

    NSMutableArray<id<rqdMediaLocalNetworkService>> *newNetworkServices = [NSMutableArray array];
    NSMutableSet<NSString *> *addedNetworkServices = [[NSMutableSet alloc] init];
    rqdMediaLocalServerDiscoveryController *discoveryController = self.discoveryController;
    NSUInteger sectionCount = [discoveryController numberOfSections];
    for (NSUInteger section = 0; section < sectionCount; ++section) {
        NSUInteger itemsCount = [discoveryController numberOfItemsInSection:section];
        for (NSUInteger index = 0; index < itemsCount; ++index) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
            id<rqdMediaLocalNetworkService> service = [discoveryController networkServiceForIndexPath:indexPath];
            if (service != nil) {
                NSString *mappedName = mapServiceName(service);
                if(![addedNetworkServices containsObject:mappedName]) {
                    [addedNetworkServices addObject:mappedName];
                    [newNetworkServices addObject:service];
                }
            }
        }
    }

    NSArray *oldNetworkServices = self.networkServices;
    GRKArrayDiff *diff = [[GRKArrayDiff alloc] initWithPreviousArray:oldNetworkServices
                                                        currentArray:newNetworkServices
                                                       identityBlock:mapServiceName
                                                       modifiedBlock:nil];

    [diff performBatchUpdatesWithCollectionView:self.collectionView
                                        section:0
                               dataSourceUpdate:^{
                                   self.networkServices = newNetworkServices;
                               } completion:nil];

    _nothingFoundLabel.hidden = self.discoveryController.foundAnythingAtAll;
}

@end
