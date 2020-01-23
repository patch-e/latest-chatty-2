//
//  BrowserViewController.h
//  LatestChatty2
//
//  Created by Alex Wayne on 3/26/09.
//  Copyright 2009. All rights reserved.
//

@interface BrowserViewController : UIViewController <WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate> {
    NSURLRequest *request;

    UIView *topStroke;
    WKWebView *webView;
    UIBarButtonItem *backButton;
    UIBarButtonItem *forwardButton;

    UIBarButtonItem *actionButton;
    UIToolbar *bottomToolbar;
    BOOL isShackLOL;
    BOOL initWithTitle;

    UIPopoverController *popoverController;
}

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) IBOutlet WKWebView *webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, strong) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, assign) BOOL isShackLOL;
@property (nonatomic, assign) BOOL isCredits;
@property (nonatomic, assign) CGPoint scrollPosition;

- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithRequest:(NSURLRequest *)request
                title:(NSString*)title
        isForShackLOL:(BOOL)isForShackLOL;

- (IBAction)action:(id)sender;
- (IBAction)refreshWebView:(id)sender;

@end
