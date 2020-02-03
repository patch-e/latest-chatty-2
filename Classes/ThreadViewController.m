//
//    ThreadViewController.m
//    LatestChatty2
//
//    Created by Alex Wayne on 3/24/09.
//    Copyright 2009. All rights reserved.
//

#import "ThreadViewController.h"
#import "SendMessageViewController.h"
#import "MBProgressHUD.h"
#import "LCBrowserType.h"

@implementation ThreadViewController

@synthesize threadId, rootPost, threadStarter, selectedIndexPath;

- (id)initWithThreadId:(NSUInteger)aThreadId {
        self = [super initWithNib];
    threadId = aThreadId;
    grippyBarPosition = [[NSUserDefaults standardUserDefaults] integerForKey:@"grippyBarPosition"];
    return self;
}

- (id)initWithStateDictionary:(NSDictionary *)dictionary {
    self = [self initWithThreadId:[[dictionary objectForKey:@"threadId"] intValue]];
    if (self) {
        storyId = [[dictionary objectForKey:@"storyId"] intValue];
        threadId = [[dictionary objectForKey:@"threadId"] intValue];
        lastReplyId = [[dictionary objectForKey:@"lastReplyId"] intValue];
        self.rootPost = [dictionary objectForKey:@"rootPost"];
        //[self didFinishLoadingModel:[dictionary objectForKey:@"rootPost"] otherData:dictionary];
        self.selectedIndexPath = (NSIndexPath*)[dictionary objectForKey:@"selectedIndexPath"];
    }
    return self;
}

- (NSDictionary *)stateDictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"Thread", @"type",
            rootPost,    @"rootPost",
            [NSNumber numberWithUnsignedInteger:storyId],    @"storyId",
            [NSNumber numberWithUnsignedInteger:threadId], @"threadId",
            selectedIndexPath, @"selectedIndexPath",
            [NSNumber numberWithUnsignedInteger:lastReplyId], @"lastReplyId",
            nil];
}

- (IBAction)refresh:(id)sender {
    [super refresh:sender];
    
    // wrapped existing loader logic in a GCD block to wait until the synchronous lol fetch
    // completes on a global background thread before loading the thread
    if (threadId > 0) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            // load the lols
            [Tag getLolTags];
            dispatch_async(dispatch_get_main_queue(), ^{
                // load the thread
                self->loader = [Post findThreadWithId:self->threadId delegate:self];
            });
        });
        
        highlightMyPost = NO;
        if ([sender isKindOfClass:[ComposeViewController class]]) highlightMyPost = YES;        
    } else {
        [self hideLoadingSpinner];
    }
}

- (void)refreshWithThreadId:(NSUInteger)_threadId {
    self.threadId = _threadId;
    [self refresh:nil];
}

- (UIViewController *)showingViewController {
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        return [LatestChatty2AppDelegate delegate].slideOutViewController;
    } else {
        return self;
    }
}

- (void)didFinishLoadingModel:(id)model otherData:(id)otherData {
    NSUInteger selectedPostID = 0;
    if (selectedIndexPath) {
        selectedPostID = [(ReplyCell*)[tableView cellForRowAtIndexPath:selectedIndexPath] post].modelId;
    }
    
    self.rootPost = (Post *)model;
    loader = nil;
    
    // Patch-E: for the latestchatty:// protocol launch, needed to check for an empty repliesArray here if a chatty URL launched the app that ulimately goes to a thread that falls outside of the user's set category filters
    if ([[rootPost repliesArray] count] > 0) {
        self.threadStarter = [[[rootPost repliesArray] objectAtIndex:0] author];
    }
    
    [super didFinishLoadingAllModels:nil otherData:otherData];
    
    // Set story data
    NSDictionary *dataDictionary = (NSDictionary *)otherData;
    storyId = [[dataDictionary objectForKey:@"storyId"] intValue];
    
    // Find the target post in the thread.
    Post *firstPost = nil;
    
    if (highlightMyPost) {
        highlightMyPost = NO;
        for (Post *post in [rootPost repliesArray]) {
            if ([post.author.lowercaseString isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"username"].lowercaseString] && post.modelId > firstPost.modelId) {
                firstPost = post;
            }
        }
    } else if (selectedIndexPath) {
        for (Post *post in [rootPost repliesArray]) {
            if (post.modelId == selectedPostID) {
                firstPost = post;
                break;
            }
        }
    } else if (rootPost.modelId == threadId) {
        firstPost = rootPost;
    } else {
        for (Post *reply in [rootPost repliesArray]) {
            if (reply.modelId == threadId) firstPost = reply;
        }
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"lolTags"]) {
        // get the lol counts dict for this post and it's replies
        NSDictionary *rootPostLolCounts = [[LatestChatty2AppDelegate delegate].lolCounts objectForKey:[NSString stringWithFormat: @"%lu", (unsigned long)rootPost.modelId]];
        if (rootPostLolCounts) {
            // iterate over keys for each post in this thread that has been tagged
            for (NSString *key in rootPostLolCounts) {
                for (Post *reply in [rootPost repliesArray]) {
                    // if we found a match, associate the tags dict to this post
                    if (reply.modelId == [key integerValue]) {
                        reply.lolCounts = [rootPostLolCounts valueForKey:key];
                    }
                }
            }
        }
    }
    
    NSLog(@"finished loading");
    [self.tableView reloadData];
    
    // Check for invalid data
    if (rootPost.body == nil) {
        threadId = 0;
        [UIAlertView showSimpleAlertWithTitle:@"Error"
                                      message:@"Thread loading failed. Could not parse the response properly."];
//        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    // Enable toolbars
    grippyBar.userInteractionEnabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    if (rootPost.pinned) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor lcCellPinnedColor]];
        [grippyBar setBackgroundColorForThread:[UIColor lcCellPinnedColor]];
        self.title = @"Pinned";
    } else {
        [self.navigationController.navigationBar setBarTintColor:[UIColor lcBarTintColor]];
        [grippyBar setBackgroundColorForThread:[UIColor lcBarTintColor]];
        self.title = @"Thread";
    }
    [grippyBar setPinnedWithValue:rootPost.pinned];
    [grippyBar setPinButtonHighlight];
    
    // Select and display the targeted post
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[rootPost repliesArray] indexOfObject:firstPost] inSection:0];
    if (indexPath == nil || indexPath.row >= [[rootPost repliesArray] count]) {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    if ([rootPost visible]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
        
    } else {
        threadId = 0;
        [UIAlertView showSimpleAlertWithTitle:@"Check your filters"
                                      message:@"Current filters do not allow viewing this thread. Check the set filters in Settings and try again."];
//        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
        
    if (postView.hidden) {
        postView.hidden = NO;
        [self resetLayout:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    postView.opaque = NO;
    postView.backgroundColor = [UIColor clearColor];
    postView.navigationDelegate = self;

    if ([[LatestChatty2AppDelegate delegate] isForceTouchEnabled]) {
        [postView setAllowsLinkPreview:YES];
    }
    
    if (![[LatestChatty2AppDelegate delegate] isPadDevice] &&
        self.navigationController.viewControllers.count == 1) {
            UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu-Button-List.png"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self.viewDeckController
                                                                          action:@selector(toggleLeftView)];
            self.navigationItem.leftBarButtonItem = menuButton;
    }
    
    if (rootPost) {
        [self.tableView reloadData];
        NSIndexPath *indexPath = selectedIndexPath;
        if (indexPath == nil) indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else {
        [self refresh:self];
    }
    
    // Load buttons
//    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
//        self.toolbar.clipsToBounds = YES;        
//        self.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
//        self.navigationItem.titleView = self.toolbar;
//    } else {
        UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu-Button-Reply.png"]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(tappedReplyButton)];
        self.navigationItem.rightBarButtonItem = replyButton;
        self.navigationItem.rightBarButtonItem.enabled = NO;
//    }
    
    // Fill in empty web view
    StringTemplate *htmlTemplate = [StringTemplate templateWithName:@"Post.html"];
#if TARGET_OS_MACCATALYST
    NSString *stylesheet = [NSString stringFromResource:@"Stylesheet-mac.css"];
#else
    NSString *stylesheet = [NSString stringFromResource:@"Stylesheet.css"];
#endif
    [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
    [postView loadHTMLString:htmlTemplate.result baseURL:nil];
    
    if (selectedIndexPath) {
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
    }
    
    // initialize scoll position property
    self.scrollPosition = CGPointMake(0, 0);
    
    UIImageView *background = [UIImageView viewWithImage:[UIImage imageNamed:@"DropShadow.png"]];
    background.frame = CGRectMake(0, 36, grippyBar.frameWidth, grippyBar.frameHeight-32);
    background.alpha = 0.75;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [grippyBar addSubview:background];
    
    [self resetLayout:NO];
    
    // top separation bar
    UIView *topStroke = [[UIView alloc] initWithFrame:CGRectMake(0, postViewContainer.frameY, 1024, 1)];
    [topStroke setBackgroundColor:[UIColor lcTopStrokeColor]];
    [topStroke setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:topStroke];
    
    // scroll indicator coloring
    [postView.scrollView setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
    
    // tap status bar to scroll replies table to the top
    postView.scrollView.scrollsToTop = NO;
    tableView.scrollsToTop = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    if (rootPost) {
        postView.hidden = NO;
//        self.toolbar.userInteractionEnabled = YES;
//        self.toolbar.hidden = NO;
    }

    if (rootPost.pinned) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor lcCellPinnedColor]];
        [grippyBar setBackgroundColorForThread:[UIColor lcCellPinnedColor]];
        self.title = @"Pinned";
    } else {
        [self.navigationController.navigationBar setBarTintColor:[UIColor lcBarTintColor]];
        [grippyBar setBackgroundColorForThread:[UIColor lcBarTintColor]];
        self.title = @"Thread";
    }
    
    [self resetLayout:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    self.toolbar.frame = self.navigationController.navigationBar.frame;
    [self.view setNeedsLayout];
    [self resetLayout:NO];

    // if there is a saved scroll position, animate the scroll to it and reinitialize the ivar
    if (self.scrollPosition.y > 0) {
        [postView.scrollView setContentOffset:self.scrollPosition animated:YES];
        self.scrollPosition = CGPointMake(0, 0);
    }
    
    // set the panning gesture delegate to this controller to monitor whether the panning should occur
    [self.viewDeckController setPanningGestureDelegate:self];
    
    // pop back to the thread, vc instantiated doesn't have a threadId
    if (threadId == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    // remove the panning gesture delegate from this controller when the view goes away
    [self.viewDeckController setPanningGestureDelegate:nil];
    
    // reset the nav bar color in case this was a pinned thread
    UINavigationBar *navBar;
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        navBar = [LatestChatty2AppDelegate delegate].contentNavigationController.navigationBar;
    } else {
        navBar = self.navigationController.navigationBar;
    }
    [navBar setBarTintColor:[UIColor lcBarTintColor]];
    
    [grippyBar setBackgroundColorForThread:[UIColor lcBarTintColor]];
    
    [loader cancel];
}

- (void)tappedDoneButton {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tappedReplyButton {
    Post *post = [[rootPost repliesArray] objectAtIndex:selectedIndexPath.row];
    
    ComposeViewController *viewController = [[ComposeViewController alloc] initWithStoryId:storyId post:post];
    [self.navigationController pushViewController:viewController animated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ComposeAppeared" object:self];
}

#pragma mark -
#pragma mark Thread pinning
- (void)togglePinThread {
    if (rootPost.pinned) { // unpin thread
        [self unPinThread];
    } else { // pin thread
        [self pinThread];
    }
    rootPost.pinned = !rootPost.pinned;
    [grippyBar setPinnedWithValue:rootPost.pinned];
    [grippyBar setPinButtonHighlight];
}

- (void)pinThread {
    [Post pin:rootPost];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor lcCellPinnedColor]];
    [grippyBar setBackgroundColorForThread:[UIColor lcCellPinnedColor]];
    
    //show pin HUD message
    NSTimeInterval theTimeInterval = 0.75;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeText];
    hud.label.text = @"Pinned!";
    hud.bezelView.color = [UIColor lcCellPinnedColor];
    [hud hideAnimated:YES afterDelay:theTimeInterval];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThreadPinned" object:self userInfo:@{@"modelId": [NSNumber numberWithUnsignedInteger:rootPost.modelId]}];
    
    self.title = @"Pinned";
}

- (void)unPinThread {
    [Post unpin:rootPost];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor lcBarTintColor]];
    [grippyBar setBackgroundColorForThread:[UIColor lcBarTintColor]];
    
    //show unpin HUD message
    NSTimeInterval theTimeInterval = 0.75;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeText];
    hud.label.text = @"Unpinned!";
    hud.bezelView.color = [UIColor lcBarTintColor];
    [hud hideAnimated:YES afterDelay:theTimeInterval];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThreadUnpinned" object:self userInfo:@{@"modelId": [NSNumber numberWithUnsignedInteger:rootPost.modelId]}];
    
    self.title = @"Thread";
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    return [[rootPost repliesArray] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {        
    static NSString *CellIdentifier = @"ReplyCell";
    
    ReplyCell *cell = (ReplyCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ReplyCell alloc] init];
    }
    
    cell.post = [[rootPost repliesArray] objectAtIndex:indexPath.row];
    cell.isThreadStarter = [cell.post.author.lowercaseString isEqualToString:threadStarter.lowercaseString];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    UIView  *background = [[UIView alloc] init];
    return background;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 16.0;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    if (indexPath == nil) return;

    Post *post = [[rootPost repliesArray] objectAtIndex:indexPath.row];
    
    // Create HTML for the post
    StringTemplate *htmlTemplate = [StringTemplate templateWithName:@"Post.html"];

#if TARGET_OS_MACCATALYST
    NSString *stylesheet = [NSString stringFromResource:@"Stylesheet-mac.css"];
#else
    NSString *stylesheet = [NSString stringFromResource:@"Stylesheet.css"];
#endif
    [htmlTemplate setString:stylesheet forKey:@"stylesheet"];
    [htmlTemplate setString:[Post formatDate:post.date] forKey:@"date"];
    [htmlTemplate setString:post.author forKey:@"author"];
    [htmlTemplate setString:[NSString stringWithFormat:@"%lu", (unsigned long)post.modelId] forKey:@"postId"];

    // set the expiration stripe's background color and size in the HTML template
//    NSLog(@"%@", [NSString hexFromUIColor:[Post colorForPostExpiration:post.date]]);
//    NSLog(@"%@", [NSString rgbaFromUIColor:[Post colorForPostExpiration:post.date]]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%f%%", [Post sizeForPostExpiration:post.date]]);
    [htmlTemplate setString:[NSString rgbaFromUIColor:[Post colorForPostExpiration:post.date withCategory:post.category]] forKey:@"expirationColor"];
    [htmlTemplate setString:[NSString stringWithFormat:@"%f%%", [Post sizeForPostExpiration:post.date]] forKey:@"expirationSize"];
    
    // create lol tags for this post if they exist and are enabled
    NSMutableString *tags;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"lolTags"] && post.lolCounts) {
        tags = [Tag buildPostViewTag:post.lolCounts];
    }
    
    // if the tags string was allocated and appended to...
    if (tags != nil && tags.length > 0) {
        // place it in the html template
        [htmlTemplate setString:@"show" forKey:@"tagDisplay"];
        [htmlTemplate setString:tags forKey:@"tags"];
    }
    
//    NSString *body = [self postBodyWithYoutubeWidgets:post.body];
    
    [htmlTemplate setString:post.body forKey:@"body"];
    [postView loadHTMLString:htmlTemplate.result baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.shacknews.com/chatty?id=%lu", (unsigned long)rootPost.modelId]]];
}

-(void)tableView:(UITableView *)_tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:_tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

//- (NSString *)postBodyWithYoutubeWidgets:(NSString *)body {
//    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"embedYoutube"]) return body;
//    
//    // Insert youtube widgets
//    if ([body isMatchedByRegex:@"<a href=\"(http://(www\\.)?youtube\\.com/watch\\?v=.*?)\">.*?</a>"]) {
//        @try {
//            CGSize youtubeSize = [[LatestChatty2AppDelegate delegate] isPadDevice] ? CGSizeMake(640, 480) : CGSizeMake(140, 105);
//            NSString *replacement = [NSString stringWithFormat:
//                                     @"<div class=\"youtube-widget\">"
//                                     @"  <object width=\"%d\" height=\"%d\">"
//                                     @"    <param name=\"movie\" value=\"$1\"></param>"
//                                     @"    <param name=\"wmode\" value=\"transparent\"></param>"
//                                     @"    <embed id=\"yt\" src=\"$1\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"%d\" height=\"%d\"></embed>"
//                                     @"  </object>"
//                                     @"  <br/>"
//                                     @"  <a href=\"$1\">$1</a>"
//                                     @"</div>",
//                                     (int)youtubeSize.width, (int)youtubeSize.height,
//                                     (int)youtubeSize.width, (int)youtubeSize.height];
//            
//            body = [body stringByReplacingOccurrencesOfRegex:@"<a href=\"(http://(www\\.)?youtube\\.com/watch\\?v=.*?)\">.*?</a>" withString:replacement];
//            
//        } @catch (NSException *exception) {
//            NSLog(@"Error inserting youtube widgets. %@", exception);
//        }
//    }
//    
//    return body;
//}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == tableView) {
        [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark WebView Methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
        
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        // author name tapped, show action sheet to search for posts or shackmessage
        // still using the oldschool shacknews profile URI pattern here
        // probably not a good idea but the shack is probably never bringing back profiles at this point so whatevs
        if ([[[navigationAction.request URL] absoluteString] isMatchedByRegex:@"shacknews\\.com/profile/.*"]) {
            // present action sheet
            [self showAuthorActions];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        LatestChatty2AppDelegate *appDelegate = (LatestChatty2AppDelegate *)[[UIApplication sharedApplication] delegate];
        UIViewController *viewController = [appDelegate viewControllerForURL:[navigationAction.request URL]];
        
        // No special controller, handle the URL.
        // Check URL for YouTube, open externally is necessary.
        // If not YouTube, open URL in browser of preference
        if (viewController == nil) {
            BOOL isYouTubeURL = [appDelegate isYouTubeURL:[navigationAction.request URL]];
            BOOL useYouTube = [[NSUserDefaults standardUserDefaults] boolForKey:@"useYouTube"];
            NSUInteger browserPref = [[NSUserDefaults standardUserDefaults] integerForKey:@"browserPref"];
            NSLog(@"browserPref: %lu", (unsigned long)browserPref);
            
            // save scroll position of web view before showing view controller
            self.scrollPosition = webView.scrollView.contentOffset;
            
            if (isYouTubeURL && useYouTube) {
                // don't open with browser preference, open YouTube app
                [[UIApplication sharedApplication] openURL:[[navigationAction.request URL] YouTubeURLByReplacingScheme]];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            // open current URL in Safari app
            if (browserPref == LCBrowserTypeSafariApp) {
                [[UIApplication sharedApplication] openURL:[navigationAction.request URL]];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            // open current URL in iOS 9 Safari modal view
            if (browserPref == LCBrowserTypeSafariView) {
                SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:[navigationAction.request URL]];
                [svc setDelegate:self];
                [svc setPreferredBarTintColor:[UIColor lcBarTintColor]];
                [svc setPreferredControlTintColor:[UIColor whiteColor]];
                [svc setModalPresentationCapturesStatusBarAppearance:YES];
                
                [[self showingViewController] presentViewController:svc animated:YES completion:nil];
                
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            // open current URL in Chrome app
            if (browserPref == LCBrowserTypeChromeApp) {
                // replace http,https:// with googlechrome://
                NSURL *chromeURL = [appDelegate urlAsChromeScheme:[navigationAction.request URL]];
                if (chromeURL != nil) {
                    [[UIApplication sharedApplication] openURL:chromeURL];
                    
                    chromeURL = nil;
                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }
            }

            viewController = [[BrowserViewController alloc] initWithRequest:navigationAction.request];
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark Grippy Bar Methods
- (void)resetLayoutAnimationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
        CGRect postViewContainerFrame = postViewContainer.frame;
        [postView setFrame:postViewContainerFrame];
        // Reload the post to fit the new view sizes.
        [self tableView:tableView didSelectRowAtIndexPath:self.selectedIndexPath];
}

- (void)resetLayout:(BOOL)animated {
    CGFloat usableHeight = self.view.frame.size.height - 24.0;
    
    CGFloat dividerLocation = 0.5;
    
    switch (grippyBarPosition) {
        case 0:
            dividerLocation = 0.33;
            break;
            
        case 1:
            dividerLocation = 0.5;
            break;
            
        case 2:
            dividerLocation = 0.66;
            break;
    }
    
    [UIView beginAnimations:@"ResizePostView" context:nil];
    {
        if (!animated){
            [UIView setAnimationDuration:0];
        }
        
        CGRect subFrame = postViewContainer.frame;
        double oldHeight = subFrame.size.height;
        double oldWidth = subFrame.size.width;
        subFrame.size.height = round(usableHeight * dividerLocation);
        subFrame.size.width = tableView.frame.size.width;
        [postViewContainer setFrame:subFrame];
        
        // When resizing, if the new height is larger than the old height,
        // resize the UIWebView immediately. Otherwise, resize it after
        // the animation completes. UIWebView content is resized immediately
        // when the size of the top level view changes instead of
        // animating smoothly.

        if (oldHeight < subFrame.size.height || oldWidth < subFrame.size.width) {
                subFrame = postView.frame;
                subFrame.size.height = round(usableHeight * dividerLocation);
                subFrame.size.width = postViewContainer.frame.size.width;
                [postView setFrame:subFrame];
        }
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(resetLayoutAnimationDidStop:finished:context:)];
        
        subFrame = grippyBar.frame;
        subFrame.origin.y = round(usableHeight * dividerLocation) - 12;
        [grippyBar setFrame:subFrame];
    
        [threadPinButton setFrame:CGRectMake(subFrame.origin.x + subFrame.size.width - 32, subFrame.origin.y - 24, 32, 32)];
        
        subFrame = tableView.frame;
        subFrame.origin.y = round(usableHeight * dividerLocation) + 24;
        subFrame.size.height = round(usableHeight * (1.0 - dividerLocation));
        [tableView setFrame:subFrame];
    }
    [UIView commitAnimations];
}

- (void)grippyBarDidSwipeUp {
    grippyBarPosition--;
    if (grippyBarPosition < 0) grippyBarPosition = 0;
    [self resetLayout:YES];
    [[NSUserDefaults standardUserDefaults] setInteger:grippyBarPosition forKey:@"grippyBarPosition"];
}

- (void)grippyBarDidSwipeDown {
    grippyBarPosition++;
    if (grippyBarPosition > 2) grippyBarPosition = 2;
    [self resetLayout:YES];
    [[NSUserDefaults standardUserDefaults] setInteger:grippyBarPosition forKey:@"grippyBarPosition"];
}

- (IBAction)tag {
    UIActionSheet *dialog = [[UIActionSheet alloc] initWithTitle:@"Tag this Post"
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                   destructiveButtonTitle:nil
                                               otherButtonTitles:@"lol", @"inf", @"unf", @"tag", @"wtf", @"wow", @"aww", nil];
    
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        [dialog showInView:[LatestChatty2AppDelegate delegate].slideOutViewController.view];
    } else {
        [dialog showInView:self.view];
    }
}

- (void)showAuthorActions {
    UIActionSheet *dialog = [[UIActionSheet alloc] initWithTitle:@"Author Actions"
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Search for Posts", @"Send a Message", @"Report", nil];
    
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        [dialog showInView:[LatestChatty2AppDelegate delegate].slideOutViewController.view];
    } else {
        [dialog showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    actionSheet = nil;
}

- (int)nextRowByTimeLevel:(int)currentRow {
    Post *currentPost = [[rootPost repliesArray] objectAtIndex:currentRow];
    
    for (int postIndex = 0; postIndex < [[rootPost repliesArray] count]; postIndex++) {
        Post *post = [[rootPost repliesArray] objectAtIndex:postIndex];
        if (post.timeLevel == currentPost.timeLevel - 1)
            return postIndex;
    }
    
    return 0;
}

- (NSInteger)previousRowByTimeLevel:(int)currentRow {
    Post *currentPost = [[rootPost repliesArray] objectAtIndex:currentRow];
    NSInteger minTimeLevel = -1, minTimeLevelPostIndex = 0;
    
    for (int postIndex = 0; postIndex < [[rootPost repliesArray] count]; postIndex++) {
        Post *post = [[rootPost repliesArray] objectAtIndex:postIndex];
        if(post.timeLevel == currentPost.timeLevel + 1)
            return postIndex;
        
        if (post.timeLevel < minTimeLevel || minTimeLevel == -1){
            minTimeLevel = post.timeLevel;
            minTimeLevelPostIndex = postIndex;
        }
    }
    
    return minTimeLevelPostIndex;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray<UIKeyCommand *>*)keyCommands {
    return @[
             [UIKeyCommand keyCommandWithInput:@"a" modifierFlags:0 action:@selector(prevTab:) discoverabilityTitle:@"Previous Subthread"],
             [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:0 action:@selector(nextTab:) discoverabilityTitle:@"Next Subthread"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(prevTabThreader:) discoverabilityTitle:@"Previous Thread"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(nextTabThreader:) discoverabilityTitle:@"Next Thread"],
             [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(refreshTableview:) discoverabilityTitle:@"Refresh Threads"],
             [UIKeyCommand keyCommandWithInput:@"p" modifierFlags:UIKeyModifierCommand action:@selector(threadPinnedKey:) discoverabilityTitle:@"Toggle Thread Pinned"],
             [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:0 action:@selector(replyToPost:) discoverabilityTitle:@"Reply to Post"]
             ];
}

- (void)threadPinnedKey:(UIKeyCommand *)sender {
    [self togglePinThread];
}

- (void)refreshTableview:(UIKeyCommand *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshView" object:self];
}

- (void)prevTabThreader:(UIKeyCommand *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PrevThread" object:self];
}

- (void)nextTabThreader:(UIKeyCommand *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NextThread" object:self];
}

- (void)prevTab:(UIKeyCommand *)sender {
    [self previous];
}

- (void)nextTab:(UIKeyCommand *)sender {
    [self next];
}

- (void)replyToPost:(UIKeyCommand *)sender {
    [self tappedReplyButton];
}


- (IBAction)previous {
    NSIndexPath *oldIndexPath = selectedIndexPath;
        
    NSIndexPath *newIndexPath;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"orderByPostDate"]) {
        newIndexPath = [NSIndexPath indexPathForRow:[self previousRowByTimeLevel:(int)oldIndexPath.row] inSection:0];
    } else if (oldIndexPath.row == 0) {
        newIndexPath = [NSIndexPath indexPathForRow:[[rootPost repliesArray] count] - 1 inSection:0];
    } else {
        newIndexPath = [NSIndexPath indexPathForRow:oldIndexPath.row - 1 inSection:0];
    }
    
    [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:tableView didSelectRowAtIndexPath:newIndexPath];    
}

- (IBAction)next {
    NSIndexPath *oldIndexPath = selectedIndexPath;
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:oldIndexPath.row + 1 inSection:0];
        
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"orderByPostDate"]) {
        newIndexPath = [NSIndexPath indexPathForRow:[self nextRowByTimeLevel:(int)oldIndexPath.row] inSection:0];
    }
    else if (oldIndexPath.row == [[rootPost repliesArray] count] - 1) {
        newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    [tableView selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:tableView didSelectRowAtIndexPath:newIndexPath];
}

- (void)grippyBarDidTapPinButton {
    [self togglePinThread];
}

- (void)grippyBarDidTapRightButton {
    [self next];
}

- (void)grippyBarDidTapLeftButton {
    [self previous];
}

- (void)grippyBarDidTapRefreshButton {
    [self refresh:nil];
}

- (void)grippyBarDidTapTagButton {
    [self tag];
}

-(void)grippyBarDidTapModButton {
    UIActionSheet *modActionSheet = [[UIActionSheet alloc] initWithTitle:@"Mod this Post"
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:@"Stupid", @"Offtopic", @"NWS", @"Political", @"Informative", @"Nuked", @"Ontopic", nil];
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        [modActionSheet showInView:[LatestChatty2AppDelegate delegate].slideOutViewController.view];
    } else {
        [modActionSheet showInView:self.view];
    }
}

#pragma mark Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    Post *post = [[rootPost repliesArray] objectAtIndex:selectedIndexPath.row];
    NSUInteger postId = [post modelId];
    NSUInteger parentId = [rootPost modelId];
    
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    
    if ([[actionSheet title] isEqualToString:@"Mod this Post"]) { //modding
        if (buttonIndex == 0) [Mod modParentId:parentId modPostId:postId mod:ModTypeStupid];
        if (buttonIndex == 1) [Mod modParentId:parentId modPostId:postId mod:ModTypeOfftopic];
        if (buttonIndex == 2) [Mod modParentId:parentId modPostId:postId mod:ModTypeNWS];
        if (buttonIndex == 3) [Mod modParentId:parentId modPostId:postId mod:ModTypePolitical];
        if (buttonIndex == 4) [Mod modParentId:parentId modPostId:postId mod:ModTypeInformative];
        if (buttonIndex == 5) [Mod modParentId:parentId modPostId:postId mod:ModTypeNuked];
        if (buttonIndex == 6) [Mod modParentId:parentId modPostId:postId mod:ModTypeOntopic];

        if (buttonIndex <= 6 && ![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"nuked"]) {
            post.category = [actionSheet buttonTitleAtIndex:buttonIndex];
            [[tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]] setNeedsLayout];
        }
        
        //show mod HUD message
        NSTimeInterval theTimeInterval = 0.75;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeText];
        hud.label.text = @"Modded!";
        hud.bezelView.color = [UIColor lcBarTintColor];
        [hud hideAnimated:YES afterDelay:theTimeInterval];
    } else if ([[actionSheet title] isEqualToString:@"Tag this Post"]) { //tagging
        [Tag tagPostId:postId tag:[actionSheet buttonTitleAtIndex:buttonIndex]];
        
        //show tag HUD message
        NSTimeInterval theTimeInterval = 0.75;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeText];
        hud.label.text = @"Tagged!";
        hud.bezelView.color = [UIColor lcBarTintColor];
        [hud hideAnimated:YES afterDelay:theTimeInterval];
    } else if ([[actionSheet title] isEqualToString:@"Author Actions"]) { //author actions
        NSString *author = [post author];
        UIViewController *viewController;
        
        // do a search for this author's posts
        if (buttonIndex == 0) {
            // reconstruct the profile URL as a string here instead of trying to pass it along or persist some other way
            // encode the author
            NSString *profilePath = [[NSString stringWithFormat:@"http://www.shacknews.com/profile/%@", author] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            viewController = [[LatestChatty2AppDelegate delegate] viewControllerForURL:[NSURL URLWithString:profilePath]];
        }
        // start a shackmessage with this author as the recipient
        if (buttonIndex == 1) {
            viewController = [[SendMessageViewController alloc] initWithRecipient:author];
        }
        // start a shackmessage to duke nuked reporting this author/post
        if (buttonIndex == 2) {
            unsigned long pid = (unsigned long)postId;
            NSString *body = [NSString stringWithFormat:@"I would like to report user \"%@\", author of post http://www.shacknews.com/chatty?id=%lu#item_%lu for not adhering to the Shacknews guidelines.", author, pid, pid];
            viewController = [[SendMessageViewController alloc] initWithReportBody:body];
        }
        
        // push the resulting view controller
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else { // long pressing
        if (buttonIndex == 0) {
            // "Reply to this Post"
            // fire the reply button method to do a reply to the long pressed post
            [self tappedReplyButton];
        } else if (buttonIndex == 1) {
            // "Reply to root post"
            // set the selected row to the 0th row in the table view
            NSIndexPath *rootPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView selectRowAtIndexPath:rootPath animated:YES scrollPosition:UITableViewScrollPositionTop];
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:rootPath];
            // fire the reply button method to do a reply to on the now selected root post
            [self tappedReplyButton];
        }
    }
}

//#pragma mark Gesture Recognizers
//
//// monitor gesture touches
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    // if gesture is panning kind (ViewDeck uses panning to bring out menu)
//    if ([gestureRecognizer.class isSubclassOfClass:[UIPanGestureRecognizer class]]) return YES;
//
//    // if gesture is swipe kind, let it pass through
//    if ([gestureRecognizer.class isSubclassOfClass:[UISwipeGestureRecognizer class]]) return YES;
//    
//    // if gesture is long press (on the navigation bar), only let it pass through if the press is on the reply button
//    if ([gestureRecognizer.class isSubclassOfClass:[UILongPressGestureRecognizer class]] ||
//        [gestureRecognizer.class isSubclassOfClass:[UITapGestureRecognizer class]]) {
//        // this will be faulty logic if there is ever another button on the nav bar other than the reply button,
//        // the back button is not included in this because its view's class is not a subclass of UIControl
//        if ([[touch.view class] isSubclassOfClass:[UIControl class]]) return YES;
//    }
//
//    return NO;
//}
//
//-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
//    // only fire on the intial long press detection
//    if(UIGestureRecognizerStateBegan == gestureRecognizer.state) {
//        UIActionSheet *dialog = [[UIActionSheet alloc] initWithTitle:@"Reply"
//                                                      delegate:self
//                                             cancelButtonTitle:@"Cancel"
//                                        destructiveButtonTitle:nil
//                                             otherButtonTitles:@"Reply to this post", @"Reply to root post", nil];
//        
//        if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
//            [dialog showInView:[LatestChatty2AppDelegate delegate].slideOutViewController.view];
//        } else {
//            [dialog showInView:self.view];
//        }
//    }
//}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [LatestChatty2AppDelegate supportedInterfaceOrientations];
}

#pragma mark Cleanup

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    tableView.delegate = nil;
}

@end
