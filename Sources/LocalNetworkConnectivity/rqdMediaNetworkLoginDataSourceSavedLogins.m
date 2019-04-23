/*****************************************************************************
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2016 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Vincent L. Cone <vincent.l.cone # tuta.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "rqdMediaNetworkLoginDataSourceSavedLogins.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>
#import "rqdMediaNetworkServerLoginInformation+Keychain.h"

static NSString *const rqdMediaNetworkLoginSavedLoginCellIdentifier = @"rqdMediaNetworkLoginSavedLoginCell";

@interface rqdMediaNetworkLoginSavedLoginCell : UITableViewCell
@end

@interface rqdMediaNetworkLoginDataSourceSavedLogins ()
@property (nonatomic) NSMutableArray<NSString *> *serverList;
@property (nonatomic, weak) UITableView *tableView;
@end
@implementation rqdMediaNetworkLoginDataSourceSavedLogins
@synthesize sectionIndex = _sectionIndex;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serverList = [NSMutableArray array];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(ubiquitousKeyValueStoreDidChange:)
                                   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                 object:[NSUbiquitousKeyValueStore defaultStore]];

        NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
        [ukvStore synchronize];
        NSArray *ukvServerList = [ukvStore arrayForKey:krqdMediaStoredServerList];
        if (ukvServerList) {
            [_serverList addObjectsFromArray:ukvServerList];
        }
        [self migrateServerlistToCloudIfNeeded];
    }
    return self;
}


- (void)migrateServerlistToCloudIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults boolForKey:krqdMediaMigratedToUbiquitousStoredServerList]) {
        /* we need to migrate from previous, insecure storage fields */
        NSArray *ftpServerList = [defaults objectForKey:krqdMediaFTPServer];
        NSArray *ftpLoginList = [defaults objectForKey:krqdMediaFTPLogin];
        NSArray *ftpPasswordList = [defaults objectForKey:krqdMediaFTPPassword];
        NSUInteger count = ftpServerList.count;

        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
                keychainItem.service = ftpServerList[i];
                keychainItem.account = ftpLoginList[i];
                keychainItem.secret.stringValue = ftpPasswordList[i];
                [keychainItem saveWithError:nil];
                [_serverList addObject:ftpServerList[i]];
            }
        }

        NSArray *plexServerList = [defaults objectForKey:krqdMediaPLEXServer];
        NSArray *plexPortList = [defaults objectForKey:krqdMediaPLEXPort];
        count = plexServerList.count;
        if (count > 0) {
            for (NSUInteger i = 0; i < count; i++) {
                [_serverList addObject:[NSString stringWithFormat:@"plex://%@:%@", plexServerList[i], plexPortList[i]]];
            }
        }

        NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
        [ukvStore setArray:_serverList forKey:krqdMediaStoredServerList];
        [ukvStore synchronize];
        [defaults setBool:YES forKey:krqdMediaMigratedToUbiquitousStoredServerList];
    }

}


- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _serverList = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:krqdMediaStoredServerList]];
    // TODO: Vincent: array diff with insert and delete
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];;
}

#pragma mark - API

- (BOOL)saveLogin:(rqdMediaNetworkServerLoginInformation *)login error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *innerError = nil;
    BOOL success = [login saveLoginInformationToKeychainWithError:&innerError];
    if(!success) {
        NSLog(@"Failed to save login with error: %@",innerError);
        if (error) {
            *error = innerError;
        }
    }
    // even if the save fails we want to add the server identifier to the iCloud list
    NSString *serviceIdentifier = [login keychainServiceIdentifier];
    [_serverList addObject:serviceIdentifier];
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:krqdMediaStoredServerList];
    [ukvStore synchronize];

    // TODO: Vincent: add row directly instead of section reload
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];

    return success;
}

- (BOOL)deleteItemAtRow:(NSUInteger)row error:(NSError * _Nullable __autoreleasing *)error
{
    NSString *serviceString = _serverList[row];
    NSError *innerError = nil;
    BOOL success = [XKKeychainGenericPasswordItem removeItemsForService:serviceString error:&innerError];
    if (!success) {
        NSLog(@"Failed to delete login with error: %@",innerError);
    }
    if (error) {
        *error = innerError;
    }

    [_serverList removeObject:serviceString];
    NSUbiquitousKeyValueStore *ukvStore = [NSUbiquitousKeyValueStore defaultStore];
    [ukvStore setArray:_serverList forKey:krqdMediaStoredServerList];
    [ukvStore synchronize];

    // TODO: Vincent: add row directly instead of section reload
    [self.tableView reloadData];
    return success;
}


#pragma mark -

- (void)configureWithTableView:(UITableView *)tableView
{
    [tableView registerClass:[rqdMediaNetworkLoginSavedLoginCell class] forCellReuseIdentifier:rqdMediaNetworkLoginSavedLoginCellIdentifier];
    self.tableView = tableView;
}

- (NSUInteger)numberOfRowsInTableView:(UITableView *)tableView
{
    return self.serverList.count;
}

- (NSString *)cellIdentifierForRow:(NSUInteger)row
{
    return rqdMediaNetworkLoginSavedLoginCellIdentifier;
}

- (void)configureCell:(UITableViewCell *)cell forRow:(NSUInteger)row
{
    NSString *serviceString = _serverList[row];
    NSURL *service = [NSURL URLWithString:serviceString];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@]", service.host, [service.scheme uppercaseString]];
    XKKeychainGenericPasswordItem *keychainItem = [XKKeychainGenericPasswordItem itemsForService:serviceString error:nil].firstObject;
    if (keychainItem) {
        cell.detailTextLabel.text = keychainItem.account;
    } else {
        cell.detailTextLabel.text = @"";
    }
}

- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRow:(NSUInteger)row
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteItemAtRow:row error:nil];
    }
}

- (void)didSelectRow:(NSUInteger)row
{
    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:self.sectionIndex] animated:YES];
    rqdMediaNetworkServerLoginInformation *login = [rqdMediaNetworkServerLoginInformation loginInformationWithKeychainIdentifier:self.serverList[row]];
    [login loadLoginInformationFromKeychainWithError:nil];
    [self.delegate loginsDataSource:self selectedLogin:login];
}

@end


@implementation rqdMediaNetworkLoginSavedLoginCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [UIColor whiteColor];
        self.detailTextLabel.textColor = [UIColor rqdMediaLightTextColor];
        self.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    }
    return self;
}

@end
