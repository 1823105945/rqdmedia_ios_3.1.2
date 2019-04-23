/*****************************************************************************
 * rqdMediaDownloadViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaDownloadViewController.h"
#import "rqdMediaHTTPFileDownloader.h"
#import "rqdMediaActivityManager.h"
#import "WhiteRaccoon.h"
#import "NSString+SupportedMedia.h"
#import "rqdMediaHTTPFileDownloader.h"

typedef NS_ENUM(NSUInteger, rqdMediaDownloadScheme) {
    rqdMediaDownloadSchemeNone,
    rqdMediaDownloadSchemeHTTP,
    rqdMediaDownloadSchemeFTP
};

@interface rqdMediaDownloadViewController () <WRRequestDelegate, UITableViewDataSource, UITableViewDelegate, rqdMediaHTTPFileDownloader, UITextFieldDelegate>
{
    NSMutableArray *_currentDownloads;
    rqdMediaDownloadScheme _currentDownloadType;
    NSString *_humanReadableFilename;
    NSMutableArray *_currentDownloadFilename;
    NSTimeInterval _startDL;

    rqdMediaHTTPFileDownloader *_httpDownloader;

    WRRequestDownload *_FTPDownloadRequest;
    NSTimeInterval _lastStatsUpdate;
    CGFloat _averageSpeed;

    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}
@end

@implementation rqdMediaDownloadViewController

+ (instancetype)sharedInstance
{
    static rqdMediaDownloadViewController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[rqdMediaDownloadViewController alloc] initWithNibName:@"rqdMediaDownloadViewController" bundle:nil];
    });

    return sharedInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        _currentDownloads = [[NSMutableArray alloc] init];
        _currentDownloadFilename = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAttributedString *coloredAttributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://myserver.com/file.mkv" attributes:@{NSForegroundColorAttributeName: [UIColor rqdMediaLightTextColor]}];
    self.urlField.attributedPlaceholder = coloredAttributedPlaceholder;

    [self.downloadButton setTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.title = NSLocalizedString(@"DOWNLOAD_FROM_HTTP", nil);
    self.whatToDownloadHelpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DOWNLOAD_FROM_HTTP_HELP", nil), [[UIDevice currentDevice] model]];
    self.urlField.delegate = self;
    self.urlField.keyboardType = UIKeyboardTypeURL;
    self.progressContainer.hidden = YES;
    self.downloadsTable.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
    self.downloadsTable.hidden = YES;

    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillAppear:(BOOL)animated
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if ([pasteboard containsPasteboardTypes:@[@"public.url"]]) {
        id pasteboardValue = [pasteboard valueForPasteboardType:@"public.url"];
        if ([pasteboardValue respondsToSelector:@selector(absoluteString)]) {
            self.urlField.text = [pasteboardValue absoluteString];
        }
    }
    [self _updateUI];
    [super viewWillAppear:animated];
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

- (IBAction)downloadAction:(id)sender
{
    if ([self.urlField.text length] > 0) {
        NSURL *URLtoSave = [NSURL URLWithString:self.urlField.text];
        if (![URLtoSave.lastPathComponent isSupportedFormat] && ![URLtoSave.lastPathComponent.pathExtension isEqualToString:@""]) {
            rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), URLtoSave.lastPathComponent]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                    otherButtonTitles:nil];
            [alert show];
            return;
        }
        if (![URLtoSave.scheme isEqualToString:@"http"] & ![URLtoSave.scheme isEqualToString:@"https"] && ![URLtoSave.scheme isEqualToString:@"ftp"]) {
            rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"SCHEME_NOT_SUPPORTED", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"SCHEME_NOT_SUPPORTED_LONG", nil), URLtoSave.scheme]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                    otherButtonTitles:nil];
            [alert show];
            return;
        }

        [_currentDownloads addObject:URLtoSave];
        [_currentDownloadFilename addObject:@""];
        self.urlField.text = @"";
        [self.downloadsTable reloadData];
        [self _triggerNextDownload];

    }
}

- (void)_updateUI
{
    _currentDownloadType != rqdMediaDownloadSchemeNone ? [self downloadStarted] : [self downloadEnded];
    [self.downloadsTable reloadData];
}

- (rqdMediaHTTPFileDownloader *)httpDownloader
{
    if (!_httpDownloader) {
        _httpDownloader = [[rqdMediaHTTPFileDownloader alloc] init];
        _httpDownloader.delegate = self;
    }
    return _httpDownloader;
}

#pragma mark - Download management

- (void)_startDownload
{
    [_currentDownloads removeObjectAtIndex:0];
    [_currentDownloadFilename removeObjectAtIndex:0];
    [self _beginBackgroundDownload];
    [self _updateUI];
}

- (void)_downloadSchemeHttp
{
    if (self.httpDownloader.downloadInProgress) {
        return;
    }
    _currentDownloadType = rqdMediaDownloadSchemeHTTP;
    if (![_currentDownloadFilename.firstObject isEqualToString:@""]) {
        _humanReadableFilename = [[_currentDownloadFilename firstObject] stringByRemovingPercentEncoding];
        [self.httpDownloader downloadFileFromURL:_currentDownloads.firstObject withFileName:_humanReadableFilename];
    } else {
        [self.httpDownloader downloadFileFromURL:_currentDownloads.firstObject];
        _humanReadableFilename = self.httpDownloader.userReadableDownloadName;
    }
    [self _startDownload];
}

- (void)_downloadSchemeFtp
{
    if (_FTPDownloadRequest) {
        return;
    }
    _currentDownloadType = rqdMediaDownloadSchemeFTP;
    [self _downloadFTPFile:_currentDownloads.firstObject];
    _humanReadableFilename = [_currentDownloads.firstObject lastPathComponent];
    [self _startDownload];
}

- (void)_beginBackgroundDownload
{
    if (!_backgroundTaskIdentifier || _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        dispatch_block_t expirationHandler = ^{
            APLog(@"Downloads were interrupted after being in background too long, time remaining: %f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = 0;
        };

        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"rqdMediaDownloader" expirationHandler:expirationHandler];
        if (_backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            APLog(@"Unable to download");
        }
    }
}

- (void)_triggerNextDownload
{
    if ([_currentDownloads count] == 0) {
        _currentDownloadType = rqdMediaDownloadSchemeNone;

        if (_backgroundTaskIdentifier && _backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = 0;
        }
        return;
    }

    [self.activityIndicator startAnimating];
    NSString *downloadScheme = [_currentDownloads.firstObject scheme];

    if ([downloadScheme isEqualToString:@"http"] || [downloadScheme isEqualToString:@"https"]) {
        [self _downloadSchemeHttp];
    } else if ([downloadScheme isEqualToString:@"ftp"]) {
        [self _downloadSchemeFtp];
    } else {
        APLog(@"Unknown download scheme '%@'", downloadScheme);
        [_currentDownloads removeObjectAtIndex:0];
        _currentDownloadType = rqdMediaDownloadSchemeNone;
    }
}

- (IBAction)cancelDownload:(id)sender
{
    if (_currentDownloadType == rqdMediaDownloadSchemeHTTP && self.httpDownloader.downloadInProgress) {
        [self.httpDownloader cancelDownload];
    } else if (_currentDownloadType == rqdMediaDownloadSchemeFTP && _FTPDownloadRequest) {
        NSURL *target = _FTPDownloadRequest.downloadLocation;
        [_FTPDownloadRequest destroy];
        [self requestCompleted:_FTPDownloadRequest];

        /* remove partially downloaded content */
        [[NSFileManager defaultManager] removeItemAtPath:target.path error:nil];
    }
}

#pragma mark - rqdMedia HTTP Downloader delegate

- (void)downloadStarted
{
    [self.activityIndicator stopAnimating];

    rqdMediaActivityManager *activityManager = [rqdMediaActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager networkActivityStarted];

    self.currentDownloadLabel.text = _humanReadableFilename;
    self.progressView.progress = 0.;
    [self.progressPercent setText:@"0%"];
    [self.speedRate setText:@"0 Kb/s"];
    [self.timeDL setText:@"00:00:00"];
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    self.progressContainer.hidden = NO;

    APLog(@"download started");
}

- (void)downloadEnded
{
    [[rqdMediaActivityManager defaultManager] networkActivityStopped];
    _currentDownloadType = rqdMediaDownloadSchemeNone;
    APLog(@"download ended");
    self.progressContainer.hidden = YES;

    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description
{
    rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED", nil)
                                                      message:description
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize  expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
        [self.progressPercent setText:[NSString stringWithFormat:@"%.1f%%", percentage*100]];
        [self.timeDL setText:[self calculateRemainingTime:receivedDataSize expectedDownloadSize:expectedDownloadSize]];
        [self.speedRate setText:[self calculateSpeedString:receivedDataSize]];
            _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
    }

    [self.progressView setProgress:percentage animated:YES];
}

- (NSString*)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;
    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize)/_averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remaingTime = [formatter stringFromDate:date];
    return remaingTime;
}

- (NSString*)calculateSpeedString:(CGFloat)receivedDataSize
{
    CGFloat speed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    NSString *string = [NSByteCountFormatter stringFromByteCount:speed countStyle:NSByteCountFormatterCountStyleDecimal];
    string = [string stringByAppendingString:@"/s"];
    return string;
}

#pragma mark - ftp networking

- (void)_downloadFTPFile:(NSURL *)URLToFile
{
    if (_FTPDownloadRequest)
        return;

    _FTPDownloadRequest = [[WRRequestDownload alloc] init];
    _FTPDownloadRequest.delegate = self;
    _FTPDownloadRequest.passive = YES;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
    NSURL *destinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", directoryPath, URLToFile.lastPathComponent]];
    _FTPDownloadRequest.downloadLocation = destinationURL;

    [_FTPDownloadRequest startWithFullURL:URLToFile];
}

- (void)requestStarted:(WRRequest *)request
{
    [self downloadStarted];
}

- (void)requestCompleted:(WRRequest *)request
{
    _FTPDownloadRequest = nil;
    [self downloadEnded];
}

- (void)requestFailed:(WRRequest *)request
{
    _FTPDownloadRequest = nil;
    [self downloadEnded];

    rqdMediaAlertView *alert = [[rqdMediaAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ERROR_NUMBER", nil), request.error.errorCode]
                                                       message:request.error.message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                             otherButtonTitles:nil];
    [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = _currentDownloads.count;
    self.downloadsTable.hidden = count > 0 ? NO : YES;
    return _currentDownloads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScheduledDownloadsCell";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor rqdMediaLightTextColor];
    }

    NSInteger row = indexPath.row;
    if ([_currentDownloadFilename[row] isEqualToString:@""])
        cell.textLabel.text = [[_currentDownloads[row] lastPathComponent] stringByRemovingPercentEncoding];
    else
        cell.textLabel.text = [[_currentDownloadFilename[row] lastPathComponent] stringByRemovingPercentEncoding];

    cell.detailTextLabel.text = [_currentDownloads[row] absoluteString];

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
        [_currentDownloads removeObjectAtIndex:indexPath.row];
        [_currentDownloadFilename removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

#pragma mark - communication with other rqdMedia objects
- (void)addURLToDownloadList:(NSURL *)aURL fileNameOfMedia:(NSString*) fileName
{
    [_currentDownloads addObject:aURL];
    if (!fileName)
        fileName = @"";
    [_currentDownloadFilename addObject:fileName];
    [self.downloadsTable reloadData];
    [self _triggerNextDownload];
}

#pragma mark - text view delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.urlField resignFirstResponder];
    return NO;
}

@end
