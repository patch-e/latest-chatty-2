//
//  LatestChatty2AppDelegate.h
//  LatestChatty2
//
//  Created by Alex Wayne on 3/16/09.
//  Copyright 2009. All rights reserved.
//

#import "RootViewController.h"
#import "StoriesViewController.h"
#import "SettingsViewController.h"
#import "ChattyViewController.h"
#import "ThreadViewController.h"
#import "ReviewThreadViewController.h"
#import "BrowserViewController.h"
#import "MessagesViewController.h"
#import "SendMessageViewController.h"
#import "IIViewDeckController.h"
#import "SloppySwiper.h"

@class ChattySplitViewController;

@interface LatestChatty2AppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    UINavigationController *contentNavigationController;
    ChattySplitViewController *splitViewController;
    NSUInteger threadId;
}

@property (nonatomic, strong) UIApplicationShortcutItem *launchedShortcutItem;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;

@property (nonatomic, strong) ChattySplitViewController *splitViewController;
@property (nonatomic, strong) IBOutlet UINavigationController *contentNavigationController;

@property (strong, nonatomic) UIViewController *centerController;
@property (strong, nonatomic) UIViewController *leftController;

@property (strong, nonatomic) NSDictionary *lolCounts;

@property (strong, nonatomic) SloppySwiper *swiper;

- (IIViewDeckController*)generateControllerStack:(NSDictionary *)launchOptions;

+ (LatestChatty2AppDelegate*)delegate;
+ (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation;
+ (UIInterfaceOrientationMask)supportedInterfaceOrientations;
+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)pushRegistration;
- (void)pushUnregistration;

//- (BOOL)reloadSavedState;

- (NSURLCredential *)userCredential;
- (BOOL)isYouTubeURL:(NSURL *)url;
- (id)urlAsChromeScheme:(NSURL *)url;
- (id)viewControllerForURL:(NSURL *)url;
- (BOOL)isPadDevice;
- (BOOL)isForceTouchEnabled;
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;
	
@end
