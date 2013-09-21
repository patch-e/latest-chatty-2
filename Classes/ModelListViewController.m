//
//  ModelListViewController.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/19/09.
//  Copyright 2009. All rights reserved.
//

#import "ModelListViewController.h"

#import "MBProgressHUD.h"

@implementation ModelListViewController

@synthesize tableView;

//TODO: scrolling hide bars
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    if (scrollView.contentOffset.y < lastOffset.y) {
//        [[self navigationController] setNavigationBarHidden:YES animated:YES];
//    } else {
//        [[self navigationController] setNavigationBarHidden:NO animated:YES];
//    }
//}
//

# pragma mark View Notifications

- (void)viewDidLoad {
    [super viewDidLoad];
    
    loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    loadingView.backgroundColor = [UIColor lcOverlayColor];
    loadingView.userInteractionEnabled = NO;
    loadingView.alpha = 0.0;
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [spinner startAnimating];
    spinner.contentMode = UIViewContentModeCenter;
    spinner.frame = CGRectMake(0, 0, self.view.frame.size.width -1, self.view.frame.size.height / 2.0 -1);
    spinner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [loadingView addSubview:spinner];

    [self.view addSubview:loadingView];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"superSecretFartMode"]) {
        int randomFartNumber = rand() % (10 - 1) + 1;
        NSLog(@"Playing Fart #%i, don't forget to wipe!", randomFartNumber);
        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"Fart%i", randomFartNumber]
                                                  withExtension:@"mp3"];
        fartSound = [[AVAudioPlayer alloc]
                     initWithContentsOfURL:soundURL error:nil];
        [fartSound play];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([fartSound isPlaying])
        [fartSound stop];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [LatestChatty2AppDelegate supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [LatestChatty2AppDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

# pragma mark Actions

- (IBAction)refresh:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [loader cancel];

    if (![sender isKindOfClass:[UIRefreshControl class]]) {
      [self showLoadingSpinner];
    }
    
}

#pragma mark Loading Spinner

- (void)showLoadingSpinner {
//    loadingView.alpha = 0.0;
//    [UIView beginAnimations:@"LoadingViewFadeIn" context:nil];
//    loadingView.alpha = 1.0;
//    [UIView commitAnimations];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    [hud setLabelText:@"Loading..."];
//    [hud setDimBackground:YES];
    [hud setColor:[UIColor lcTableBackgroundColor]];
    if (![self isKindOfClass:[ThreadViewController class]]) {
        [hud setYOffset:+33];
    }
}

- (void)hideLoadingSpinner {
//    [UIView beginAnimations:@"LoadingViewFadeOut" context:nil];
//    loadingView.alpha = 0.0;
//    [UIView commitAnimations];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (BOOL)loading {
    return loadingView.alpha > 0;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Override this method
    return [[UITableViewCell alloc] initWithFrame:CGRectZero];
}

#pragma mark Data Loading Callbacks

// Fade in table cells
- (void)didFinishLoadingAllModels:(NSArray *)models otherData:(id)otherData {
    [self hideLoadingSpinner];
  
    // Create cells
    [self.tableView reloadData];

    // Fade them in
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        cell.alpha = 0.0;
        [UIView beginAnimations:[NSString stringWithFormat:@"FadeInStoriesTable_%@", [cell description]] context:nil];
        cell.alpha = 1.0;
        [UIView commitAnimations];
    }
}

- (void)didFinishLoadingModel:(id)aModel otherData:(id)otherData {
    [self didFinishLoadingAllModels:nil otherData:otherData];
}

- (void)didFailToLoadModels {
    loader = nil;
    [self hideLoadingSpinner];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                  message:@"I could not connect to the server. Check your internet connection or you server address in your settings. Or try again later."
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
    [alert show];
}

#pragma mark Cleanup


@end
