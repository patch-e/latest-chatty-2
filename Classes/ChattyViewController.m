//
//  ChattyViewController.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/17/09.
//  Copyright 2009. All rights reserved.
//

#import "ChattyViewController.h"

#include "ThreadViewController.h"
#include "NoContentController.h"

@interface ChattyViewController ()

-(void)loadMorePosts;

@end

@implementation ChattyViewController

@synthesize threadController, storyId, threads, refreshControl;

+ (ChattyViewController*)chattyControllerWithLatest {
    return [self chattyControllerWithStoryId:0];
}

+ (ChattyViewController*)chattyControllerWithStoryId:(NSUInteger)aStoryId {//
    return [[ChattyViewController alloc] initWithStoryId:aStoryId];
}

- (id)initWithLatestChatty {
    return [self initWithStoryId:0];
}

- (id)initWithStoryId:(NSUInteger)aStoryId {
	self = [super initWithNib];
    self.storyId = aStoryId;
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        self.threadController = [[ThreadViewController alloc] initWithThreadId:0];
    }

    self.title = @"Loading...";
    
	return self;
}

- (id)initWithStateDictionary:(NSDictionary *)dictionary {
	if( self = [self initWithStoryId:[[dictionary objectForKey:@"storyId"] intValue]] ){
		
		self.storyId = [[dictionary objectForKey:@"storyId"] intValue];
		self.threads = [dictionary objectForKey:@"threads"];
		self.title =   [dictionary objectForKey:@"title"];
		lastPage =     [[dictionary objectForKey:@"lastPage"] intValue];
		currentPage =  [[dictionary objectForKey:@"currentPage"] intValue];
		
		indexPathToSelect = [dictionary objectForKey:@"selectedIndexPath"];
	}
	return self;
}

- (NSDictionary *)stateDictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Chatty", @"type",
									   [NSNumber numberWithInt:self.storyId], @"storyId",
									   threads, @"threads",
									   self.title, @"title",
									   [NSNumber numberWithInt:lastPage], @"lastPage",
									   [NSNumber numberWithInt:currentPage], @"currentPage", nil];
	
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (selectedIndexPath) [dictionary setObject:selectedIndexPath forKey:@"selectedIndexPath"];
	
	return dictionary;
}

- (void)setTitle:(NSString *)newTitle {
    newTitle = [newTitle stringByReplacingOccurrencesOfString:@": " withString:@":\n"];
    [(UILabel*)self.navigationItem.titleView setText:newTitle];
    [super setTitle:newTitle];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    [LatestChatty2AppDelegate delegate].contentNavigationController.delegate = self;
	
	if (threads == nil || [threads count] == 0) {
		[self refresh:self.refreshControl];
	} else {
		[self.tableView reloadData];
	}

    if (![[LatestChatty2AppDelegate delegate] isPadDevice]) {
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuIcon.24.png"]
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self.viewDeckController
                                                                      action:@selector(toggleLeftView)];
        self.navigationItem.leftBarButtonItem = menuButton;
    }
	
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PenIcon.24.png"]
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(tappedComposeButton)];
    self.navigationItem.rightBarButtonItem = composeButton;
    
	composeButton.enabled = (self.storyId > 0);
    
    self.tableView.hidden = YES;
    
    shouldCollapse = [[NSUserDefaults standardUserDefaults] boolForKey:@"collapse"];
    
    // replaced open source pull-to-refresh with native SDK refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor lightGrayColor]];
    
    [self.tableView addSubview:self.refreshControl];
    
    // iOS7 testing
//    [self setEdgesForExtendedLayout:UIRectEdgeLeft|UIRectEdgeRight|UIRectEdgeBottom];
//    [tableView setContentInset:UIEdgeInsetsMake(20.0, 0, 0, 0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [tableView reloadData];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    shouldCollapse = [defaults boolForKey:@"collapse"];
    
    if ([defaults boolForKey:@"darkMode"]) {
        self.tableView.separatorColor = [UIColor lcSeparatorDarkColor];
        self.tableView.backgroundColor = [UIColor lcTableBackgroundDarkColor];
    } else {
        self.tableView.separatorColor = [UIColor lcSeparatorColor];
        self.tableView.backgroundColor = [UIColor lcTableBackgroundColor];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [loader cancel];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	if(viewController == self.threadController)
		[threadController resetLayout:YES];
}

- (void)refresh:(id)sender {
	[super refresh:sender];
	currentPage = 1;
	
	if (storyId > 0) {
        loader = [Post findAllWithStoryId:self.storyId delegate:self];        
    } else {
        loader = [Post findAllInLatestChattyWithDelegate:self];
    }
    
//    if (storyId > 0) {
//        loader = [[PinnedThreadsLoader loadPinnedThreadsThenStoryId:self.storyId for:self] retain];        
//    } else {
//        loader = [[PinnedThreadsLoader loadPinnedThreadsThenLatestChattyFor:self] retain];
//    }
}

- (void)didFinishLoadingAllModels:(NSArray *)models otherData:(id)otherData {
	NSUInteger page = [[otherData objectForKey:@"page"] intValue];
	self.navigationItem.rightBarButtonItem.enabled = YES;
	BOOL hasPosts = [models count] > 0;
	self.navigationItem.rightBarButtonItem.enabled = hasPosts;
    
	if (page <= 1) {
		if (hasPosts) self.storyId = [[models objectAtIndex:0] storyId];
        if (shouldCollapse) {
            self.threads = [self removeCollapsedThreadsFromArray:models];
        } else {
            self.threads = [NSMutableArray arrayWithArray:models];
        }
	} else {
        NSMutableArray *mutableThreadsArray = [NSMutableArray arrayWithArray:self.threads];
        NSArray *newThreads = [self removeDuplicateThreadsFromArray:models];
        if (shouldCollapse) {
            newThreads = [self removeCollapsedThreadsFromArray:newThreads];
        }
        [mutableThreadsArray addObjectsFromArray:newThreads];
        self.threads = mutableThreadsArray;
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	}
	
	lastPage = [[otherData objectForKey:@"lastPage"] intValue];
	
	NSMutableDictionary* postHistoryDict = [NSMutableDictionary dictionaryWithDictionary:
                                            [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"PostCountHistory"]];
	
	// Filter Posts
	NSMutableArray *filteredThreads = [NSMutableArray array];
	for (Post *rootPost in self.threads) {
		NSString *modelID = [NSString stringWithFormat:@"%d", rootPost.modelId];
		NSNumber *numPosts = [postHistoryDict objectForKey:modelID];
		if( numPosts ){
			rootPost.newReplies = rootPost.replyCount-[numPosts intValue];
		}
		else rootPost.newReplies = rootPost.replyCount;
		
		[postHistoryDict setObject:[NSNumber numberWithInt:rootPost.replyCount] forKey:modelID];
        if ([rootPost visible]) {
            [filteredThreads addObject:rootPost];
        }
	}
	self.threads = filteredThreads;
	
	[[NSUserDefaults standardUserDefaults] setValue:postHistoryDict forKey:@"PostCountHistory"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self.tableView reloadData];
	loader = nil;
	
	NSDictionary *dataDictionary = (NSDictionary *)otherData;
	self.storyId = [[dataDictionary objectForKey:@"storyId"] intValue];
	self.title   = [dataDictionary objectForKey:@"storyName"];

    // Override super method so there is no fade if we are loading a second page.
	if (page <= 1) {
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
        
		[super didFinishLoadingAllModels:models otherData:otherData];
	} else {
        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        } else {
            // Hide the loader
            [self hideLoadingSpinner];
        }
		
		// Refresh the table
		[self.tableView reloadData];
	}
	
	// Record this refresh
	if (hasPosts) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSUInteger oldLastRefresh = [defaults integerForKey:@"lastRefresh"];
		NSUInteger newLastRefresh = [[models objectAtIndex:0] lastReplyId];
		if (newLastRefresh > oldLastRefresh) {
            [defaults setInteger:newLastRefresh forKey:@"lastRefresh"];
        }
	}
    
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        [LatestChatty2AppDelegate delegate].contentNavigationController.viewControllers = [NSArray arrayWithObject:threadController];
    }
    
    if (self.threads.count == 0) {
        [UIAlertView showSimpleAlertWithTitle:@"LatestChatty"
                                      message:@"There was an error loading the chatty. Please try again."];
        return;
    }
    
    self.tableView.hidden = NO;
}

// Filter any duplicate threads out. These threads have drifted to the next page since the last page was loaded.
- (NSArray*)removeDuplicateThreadsFromArray:(NSArray*)threadArray {
    NSMutableArray *mutableThreads = [NSMutableArray arrayWithArray:threadArray];
    
    NSIndexSet *duplicateIndexes = [mutableThreads indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Post *newThread = (Post*)obj;
        
        for (Post *existingThread in self.threads) {
            if (existingThread.modelId == newThread.modelId) {
                return YES;
            }
        }
        return NO;
    }];
    
    [mutableThreads removeObjectsAtIndexes:duplicateIndexes];
    return mutableThreads;
}

// Filter any collapsed threads out.
- (NSMutableArray*)removeCollapsedThreadsFromArray:(NSArray*)threadArray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSMutableArray *mutableThreads = [NSMutableArray arrayWithArray:threadArray];
    NSMutableArray *collapsedThreads = [NSMutableArray arrayWithArray:[defaults objectForKey:@"collapsedThreads"]];

    NSIndexSet *collapseIndexes = [mutableThreads indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Post *thread = (Post*)obj;
        
        for (NSDictionary *collapsedThreadDict in collapsedThreads) {
            if (thread.modelId == [[collapsedThreadDict objectForKey:@"modelId"] integerValue]) {
                return YES;
            }
        }
        return NO;
    }];
    
    [mutableThreads removeObjectsAtIndexes:collapseIndexes];
    return mutableThreads;
}

#pragma mark Actions

- (void)tappedComposeButton {
    ComposeViewController *viewController = [[ComposeViewController alloc] initWithStoryId:storyId post:nil];
    
    if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
        [LatestChatty2AppDelegate delegate].contentNavigationController.viewControllers = [NSArray arrayWithObject:viewController];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ComposeAppeared" object:self];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    // only fire on the intial long press detection
    if(UIGestureRecognizerStateBegan == gestureRecognizer.state) {
        // grab the long press point
        CGPoint longPressPoint = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:longPressPoint];
        if (indexPath == nil) {
            //NSLog(@"long press on table view but not on a row");
        }
        else {
            //NSLog(@"long press on table view at row %d", indexPath.row);
            
            // get reference to this thread being long pressed
            Post *thread = [threads objectAtIndex:indexPath.row];
            // remove this thread from the threads model and animate it out of the table
            [self.threads removeObject:thread];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            
            // access defaults and collapsedThreads array from user defaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *collapsedThreads = [NSMutableArray arrayWithArray:[defaults objectForKey:@"collapsedThreads"]];
            
            // create dictionary from collapsed thread's id/date, add to array and sync
            NSDictionary *collapsedThreadDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [NSNumber numberWithInteger:thread.modelId], @"modelId",
                                                 thread.date, @"date",
                                                 nil];
            [collapsedThreads addObject:collapsedThreadDict];
            [defaults setObject:collapsedThreads forKey:@"collapsedThreads"];
            [defaults synchronize];
        }
    }
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (currentPage < lastPage) return [threads count] + 1;
	return [threads count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [threads count]) {
		ThreadCell *cell = (ThreadCell *)[aTableView dequeueReusableCellWithIdentifier:@"ThreadCell"];
		if (cell == nil) {
			cell = [[ThreadCell alloc] init];
		}
		
		// Set up the cell...
        if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
		cell.storyId = storyId;
		cell.rootPost = [threads objectAtIndex:indexPath.row];
		
        if (shouldCollapse) {
            // initialize long press gesture for super collapse
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
            longPress.minimumPressDuration = 2.0; //seconds
            longPress.delegate = self;
            [cell addGestureRecognizer:longPress];
        }

		return cell;
	} else {
		UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
        [cell setBackgroundColor:[UIColor clearColor]];
        UIView *selectionView = [[UIView alloc] initWithFrame:CGRectMake(cell.frameX, cell.frameY, cell.frameWidth, cell.frameHeight-1)];
        selectionView.backgroundColor = [UIColor clearColor];
        cell.selectedBackgroundView = selectionView;
        
        UIActivityIndicatorView *cellSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        UIView *cellTopStroke = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frameWidth, 1)];
        cellTopStroke.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cellTopStroke.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.08f];
        
        [cell.contentView addSubview:cellTopStroke];
        [cell.contentView addSubview:cellSpinner];
        
        [cellSpinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        [cellSpinner setCenter:cell.contentView.center];
        [cellSpinner startAnimating];
        
		return cell;
	}
	
	return nil;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [threads count]) {
        Post *thread = [threads objectAtIndex:indexPath.row];
        
        [LatestChatty2AppDelegate delegate].contentNavigationController.viewControllers = [NSArray array];
        [[LatestChatty2AppDelegate delegate].contentNavigationController pushViewController:threadController animated:NO];
        
        if ([[LatestChatty2AppDelegate delegate] isPadDevice]) {
            [threadController refreshWithThreadId:thread.modelId];
        } else {
            [self.navigationController pushViewController:[[ThreadViewController alloc] initWithThreadId:thread.modelId] animated:YES];
        }
        
        thread.newReplies = 0;
        [[tableView cellForRowAtIndexPath:indexPath] setNeedsLayout];
        
    } else {
        [self loadMorePosts];
	}
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [threads count]) {
        [self loadMorePosts];
    }
}

-(void)loadMorePosts {
    [loader cancel];
    currentPage++;
    loader = [Post findAllWithStoryId:storyId pageNumber:currentPage delegate:self];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [loader cancel];
    
	if ([LatestChatty2AppDelegate delegate] != nil && [LatestChatty2AppDelegate delegate].contentNavigationController != nil) {
        [LatestChatty2AppDelegate delegate].contentNavigationController.delegate = nil;
    }

    indexPathToSelect = nil;
    

}

@end
