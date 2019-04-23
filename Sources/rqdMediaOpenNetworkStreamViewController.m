/*****************************************************************************
 * rqdMediaOpenNetworkStreamViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Adam Viaud <mcnight # mcnight.fr>
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaOpenNetworkStreamViewController.h"
#import "VLCPlaybackController.h"
#import "VLCLibraryViewController.h"
#import "rqdMediaMenuTableViewController.h"
#import "rqdMediaStreamingHistoryCell.h"
#import "UIDevice+rqdMedia.h"

@interface rqdMediaOpenNetworkStreamViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, rqdMediaStreamingHistoryCellMenuItemProtocol>
{
    NSMutableArray *_recentURLs;
    NSMutableDictionary *_recentURLTitles;
}
@end

@implementation rqdMediaOpenNetworkStreamViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{krqdMediaRecentURLs : @[], krqdMediaRecentURLTitles : @{}, krqdMediaPrivateWebStreaming : @(NO)};

    [defaults registerDefaults:appDefaults];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updatePasteboardTextInURLField];
}

- (void)ubiquitousKeyValueStoreDidChange:(NSNotification *)notification
{
    /* TODO: don't blindly trust that the Cloud knows best */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:krqdMediaRecentURLs]];
    _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[[NSUbiquitousKeyValueStore defaultStore] dictionaryForKey:krqdMediaRecentURLTitles]];
    [self.historyTableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(ubiquitousKeyValueStoreDidChange:)
                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                             object:[NSUbiquitousKeyValueStore defaultStore]];

    /* force store update */
    NSUbiquitousKeyValueStore *ubiquitousKeyValueStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousKeyValueStore synchronize];

    /* fetch data from cloud */
    _recentURLs = [NSMutableArray arrayWithArray:[[NSUbiquitousKeyValueStore defaultStore] arrayForKey:krqdMediaRecentURLs]];
    _recentURLTitles = [NSMutableDictionary dictionaryWithDictionary:[[NSUbiquitousKeyValueStore defaultStore] dictionaryForKey:krqdMediaRecentURLTitles]];

    /* merge data from local storage (aka legacy rqdMedia versions) */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *localRecentUrls = [defaults objectForKey:krqdMediaRecentURLs];
    if (localRecentUrls != nil) {
        if (localRecentUrls.count != 0) {
            [_recentURLs addObjectsFromArray:localRecentUrls];
            [defaults setObject:nil forKey:krqdMediaRecentURLs];
            [ubiquitousKeyValueStore setArray:_recentURLs forKey:krqdMediaRecentURLs];
            [ubiquitousKeyValueStore synchronize];
        }
    }

    /*
     * Observe changes to the pasteboard so we can automatically paste it into the URL field.
     * Do not use UIPasteboardChangedNotification because we have copy actions that will trigger it on this screen.
     * Instead when the user comes back to the application from the background (or the inactive state by pulling down notification center), update the URL field.
     * Using the 'active' rather than 'foreground' notification for future proofing if iOS ever allows running multiple apps on the same screen (which would allow the pasteboard to be changed without truly backgrounding the app).
     */
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:[UIApplication sharedApplication]];

    [self.openButton setTitle:NSLocalizedString(@"OPEN_NETWORK", nil) forState:UIControlStateNormal];
    [self.privateModeLabel setText:NSLocalizedString(@"PRIVATE_PLAYBACK_TOGGLE", nil)];
    UILabel *scanSubModelabel = self.ScanSubModeLabel;
    [scanSubModelabel setText:NSLocalizedString(@"SCAN_SUBTITLE_TOGGLE", nil)];
    [scanSubModelabel setAdjustsFontSizeToFitWidth:YES];
    [scanSubModelabel setNumberOfLines:0];
    self.title = NSLocalizedString(@"OPEN_NETWORK", nil);
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    [self.whatToOpenHelpLabel setText:NSLocalizedString(@"OPEN_NETWORK_HELP", nil)];
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    self.historyTableView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];

    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://myserver.com/file.mkv" attributes:@{NSForegroundColorAttributeName: [UIColor rqdMediaLightTextColor]}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // This will be called every time this VC is opened by the side menu controller
    [self updatePasteboardTextInURLField];

    // Registering a custom menu item for renaming streams
    NSString *renameTitle = NSLocalizedString(@"BUTTON_RENAME", nil);
    SEL renameStreamSelector = @selector(renameStream:);
    UIMenuItem *renameItem = [[UIMenuItem alloc] initWithTitle:renameTitle action:renameStreamSelector];
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    [sharedMenuController setMenuItems:@[renameItem]];
    [sharedMenuController update];
}

- (void)updatePasteboardTextInURLField
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if ([pasteboard containsPasteboardTypes:@[@"public.url"]])
        self.urlField.text = [[pasteboard valueForPasteboardType:@"public.url"] absoluteString];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.privateToggleSwitch.on = [defaults boolForKey:krqdMediaPrivateWebStreaming];
    self.ScanSubToggleSwitch.on = [defaults boolForKey:krqdMediahttpScanSubtitle];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:[UIApplication sharedApplication]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.privateToggleSwitch.on forKey:krqdMediaPrivateWebStreaming];
    [defaults setBool:self.ScanSubToggleSwitch.on forKey:krqdMediahttpScanSubtitle];

    /* force update before we leave */
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];

    [super viewWillDisappear:animated];
}

- (CGSize)contentSizeForViewInPopover {
    return [self.view sizeThatFits:CGSizeMake(320, 800)];
}

#pragma mark - UI interaction
- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)goBack:(id)sender
{
    [self.view endEditing:YES];
    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
}

- (IBAction)openButtonAction:(id)sender
{
    if ([self.urlField.text length] <= 0 || [NSURL URLWithString:self.urlField.text] == nil) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"URL_NOT_SUPPORTED", nil)
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    if (!self.privateToggleSwitch.on) {
        NSString *urlString = self.urlField.text;
        if ([_recentURLs indexOfObject:urlString] != NSNotFound)
            [_recentURLs removeObject:urlString];

        if (_recentURLs.count >= 100)
            [_recentURLs removeLastObject];
        [_recentURLs addObject:urlString];
        [[NSUbiquitousKeyValueStore defaultStore] setArray:_recentURLs forKey:krqdMediaRecentURLs];

        [self.historyTableView reloadData];
    }
    [self.urlField resignFirstResponder];
    [self _openURLStringAndDismiss:self.urlField.text];
}

- (void)renameStreamFromCell:(UITableViewCell *)cell {
    NSIndexPath *cellIndexPath = [self.historyTableView indexPathForCell:cell];
    NSString *renameString = NSLocalizedString(@"BUTTON_RENAME", nil);
    NSString *cancelString = NSLocalizedString(@"BUTTON_CANCEL", nil);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:renameString
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelString
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *streamTitle = alertController.textFields.firstObject.text;
        [self renameStreamWithTitle:streamTitle atIndex:cellIndexPath.row];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = cell.textLabel.text;

        [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                          object:textField
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          okAction.enabled = (textField.text.length != 0);
                                                      }];
    }];

    [alertController addAction:cancelAction];
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)renameStreamWithTitle:(NSString *)title atIndex:(NSInteger)index
{
    [_recentURLTitles setObject:title forKey:[@(index) stringValue]];
    [[NSUbiquitousKeyValueStore defaultStore] setDictionary:_recentURLTitles forKey:krqdMediaRecentURLTitles];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.historyTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _recentURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StreamingHistoryCell";

    rqdMediaStreamingHistoryCell *cell = (rqdMediaStreamingHistoryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[rqdMediaStreamingHistoryCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.delegate = self;
        [cell customizeAppearance];
    }

    NSString *content = [_recentURLs[indexPath.row] stringByRemovingPercentEncoding];
    NSString *possibleTitle = _recentURLTitles[[@(indexPath.row) stringValue]];

    cell.detailTextLabel.text = content;
    cell.textLabel.text = (possibleTitle != nil) ? possibleTitle : [content lastPathComponent];

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor rqdMediaDarkBackgroundColor];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_recentURLs removeObjectAtIndex:indexPath.row];
        [_recentURLTitles removeObjectForKey:[@(indexPath.row) stringValue]];
        [[NSUbiquitousKeyValueStore defaultStore] setArray:_recentURLs forKey:krqdMediaRecentURLs];
        [[NSUbiquitousKeyValueStore defaultStore] setDictionary:_recentURLTitles forKey:krqdMediaRecentURLTitles];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.historyTableView deselectRowAtIndexPath:indexPath animated:NO];
    [self _openURLStringAndDismiss:_recentURLs[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView
    performAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    NSString *actionText = NSStringFromSelector(action);

    if ([actionText isEqualToString:@"copy:"])
        [UIPasteboard generalPasteboard].string = _recentURLs[indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView
 canPerformAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    NSString *actionText = NSStringFromSelector(action);

    if ([actionText isEqualToString:@"copy:"])
        return YES;

    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - internals
- (void)_openURLStringAndDismiss:(NSString *)url
{
    NSURL *playbackURL = [NSURL URLWithString:url];
    NSURL *subtitlesURL = nil;

    if (([playbackURL.scheme isEqualToString:@"http"] || [playbackURL.scheme isEqualToString:@"https"]) && self.ScanSubToggleSwitch.on) {
        subtitlesURL = [self _checkURLofSubtitle:playbackURL];
    }

    VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];
    VLCMediaList *medialist = [[VLCMediaList alloc] init];
    [medialist addMedia:media];
    [[rqdMediaPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:subtitlesURL.absoluteString];
}

- (NSURL *)_checkURLofSubtitle:(NSURL *)url
{
    NSCharacterSet *characterFilter = [NSCharacterSet characterSetWithCharactersInString:@"\\.():$"];
    NSString *subtitleFileExtensions = [[kSupportedSubtitleFileExtensions componentsSeparatedByCharactersInSet:characterFilter] componentsJoinedByString:@""];
    NSArray *arraySubtitleFileExtensions = [subtitleFileExtensions componentsSeparatedByString:@"|"];
    NSURL *urlWithoutExtension = [url URLByDeletingPathExtension];
    NSUInteger count = arraySubtitleFileExtensions.count;

    for (int i = 0; i < count; i++) {
        NSURL *checkURL = [urlWithoutExtension URLByAppendingPathExtension:arraySubtitleFileExtensions[i]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:checkURL];
        request.HTTPMethod = @"HEAD";

        NSURLResponse *response = nil;
        NSError *error = nil;
        [self sendSynchronousRequest:request returningResponse:&response error:&error];
        NSInteger httpStatus = [(NSHTTPURLResponse *)response statusCode];

        if (httpStatus == 200) {
            APLog(@"%s:found matching spu file: %@", __PRETTY_FUNCTION__, checkURL);
            return checkURL;
        }
    }
    return nil;
}

- (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSError __block *erreur = NULL;
    NSData __block *data;
    BOOL __block reqProcessed = false;
    NSURLResponse __block *urlResponse;

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        urlResponse = _response;
        erreur = _error;
        data = _data;
        reqProcessed = true;
    }] resume];

    while (!reqProcessed) {
        [NSThread sleepForTimeInterval:0];
    }

    *response = urlResponse;
    *error = erreur;
    return data;
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
