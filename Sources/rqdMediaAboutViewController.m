/*****************************************************************************
 * rqdMediaAboutViewController.m
 * rqdMedia for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *          Tamas Timar <ttimar.rqdmedia # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "rqdMediaAboutViewController.h"
#import "AboutView.h"

@interface rqdMediaAboutViewController ()
{
    UIWebView *_webView;
}

@end

@implementation rqdMediaAboutViewController

//- (void)loadView
//{
//    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    self.view.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
//    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

//    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
//    _webView.clipsToBounds = YES;
////    _webView.delegate = self;
//    _webView.backgroundColor = [UIColor clearColor];
//    _webView.opaque = NO;
//    _webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
//    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.view addSubview:_webView];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor colorWithRed:31/255.0 green:31/255.0 blue:31/255.0 alpha:1];
    self.title=@"RQD";
    AboutView *aboutView=[[[NSBundle mainBundle]loadNibNamed:@"AboutView" owner:self options:nil] lastObject];
    aboutView.frame=self.view.frame;
    [self.view addSubview:aboutView];
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];

//    NSMutableString *htmlContent = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"About Contents" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
//    [_webView loadHTMLString:[NSString stringWithString:htmlContent] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
//    htmlContent = nil;
}

//- (BOOL)shouldAutorotate
//{
//    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
//        return NO;
//    return YES;
//}
//
//- (IBAction)goBack:(id)sender
//{
//    [[rqdMediaSidebarController sharedInstance] toggleSidebar];
//}
//
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    NSURL *requestURL = request.URL;
//    if (![requestURL.scheme isEqualToString:@""])
//        return ![[UIApplication sharedApplication] openURL:requestURL];
//    else
//        return YES;
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    _webView.backgroundColor = [UIColor rqdMediaDarkBackgroundColor];
//    _webView.opaque = YES;
//}
//
//- (IBAction)openContributePage:(id)sender
//{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.videolan.org/contribute.html"]];
//}

@end
