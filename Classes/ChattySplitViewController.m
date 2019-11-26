//
//  ChattySplitViewController.m
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

#import "ChattySplitViewController.h"

#import "ChattySplitViewPrimaryContainer.h"
#import "ChattySplitViewRootVCProtocol.h"
#import "NoContentController.h"

static CGFloat const kChattySplitViewCollapsedWidth = 25.f;
static CGFloat const kChattySplitViewExpandedColumnWidth = 345.f;

@interface ChattySplitViewController () <UISplitViewControllerDelegate>
@property (nonatomic) ChattySplitViewControllerPrimaryContainer *primaryContainer;
@property (nonatomic) UINavigationController *primaryVC;
@property (nonatomic) UINavigationController *detailVC;
@property (nonatomic) BOOL didFirstAppear;
@end

@implementation ChattySplitViewController

- (instancetype)initWithPrimary:(UINavigationController *)primaryVC
                         detail:(UINavigationController *)detailVC {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _primaryVC = primaryVC;
        _detailVC = detailVC;
        _primaryContainer = [[ChattySplitViewControllerPrimaryContainer alloc] initWithViewController:_primaryVC];
        [_primaryContainer.tabButton addTarget:self
                                        action:@selector(togglePrimaryTapped:)
                              forControlEvents:UIControlEventTouchUpInside];
        self.delegate = self;
        self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        self.viewControllers = @[_primaryContainer, detailVC];
        [self setMinimumPrimaryColumnWidth: kChattySplitViewExpandedColumnWidth];
        [self setMaximumPrimaryColumnWidth: kChattySplitViewExpandedColumnWidth];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSCAssert(NO, @"Nibs are bad, do not use them");
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor darkGrayColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_didFirstAppear) {
        _primaryContainer.tabButtonVisible =
            self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
        _didFirstAppear = YES;
    }
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        strongSelf.primaryContainer.tabButtonVisible =
        (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
    } completion:nil];
}

#pragma mark - Handling Expanding/Collapsing primary

- (void)togglePrimaryTapped:(UIButton *)sender {
    [self togglePrimaryAnimated:YES];
}

- (void)togglePrimaryAnimated:(BOOL)animated {
    BOOL collapsed = !_primaryContainer.collapsed;
    
    CGFloat primaryWidth = collapsed ? kChattySplitViewCollapsedWidth : kChattySplitViewExpandedColumnWidth;
    
    // hax: basically we want to switch to the appropriate layout before (and only before) a collapse,
    // but we want to do it after otherwise, to make layout work appropriately.
    if (collapsed) {
        _primaryContainer.collapsed = YES;
    }
    
    __weak __typeof(self) weakSelf = self;
    dispatch_block_t adjustBlock = ^{
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        [self setMinimumPrimaryColumnWidth:primaryWidth];
        [self setMaximumPrimaryColumnWidth:primaryWidth];
        
        if (!collapsed) {
            strongSelf.primaryContainer.collapsed = NO;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:.15 animations:adjustBlock];
    }
    else {
        adjustBlock();
    }
}

- (void)forceCollapse {
    [self togglePrimaryAnimated:YES];
}

#pragma mark - UISplitViewControllerDelegate

+ (NSArray<UIViewController *> *)pivotableVCsFromViewControllers:(NSArray<UIViewController *> *)stack
                                                        pivotIdx:(nullable NSUInteger *)pivotIdx {
    NSUInteger idx = [stack indexOfObjectPassingTest:^BOOL(__kindof UIViewController * _Nonnull obj,
                                                                  NSUInteger idx,
                                                                  BOOL * _Nonnull stop) {
        if (![obj conformsToProtocol:@protocol(ChattySplitViewRootVCProtocol)]) {
            return NO;
        }
        
        id<ChattySplitViewRootVCProtocol> possibleRoot = (id<ChattySplitViewRootVCProtocol>)obj;
        return [possibleRoot canActAsRootForSplitViewEvents];
    }];
    if (pivotIdx) {
        *pivotIdx = idx;
    }
    
    return idx == NSNotFound ? @[] : [stack subarrayWithRange:NSMakeRange(idx, stack.count - idx)];
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    NSArray<UIViewController *> *viewControllersToMove =
        [ChattySplitViewController pivotableVCsFromViewControllers:_detailVC.viewControllers
                                                          pivotIdx:nil];
    
    _detailVC.viewControllers = @[];
    _primaryVC.viewControllers = [[_primaryVC viewControllers] arrayByAddingObjectsFromArray:viewControllersToMove];
    return YES;
}

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController
separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    
    NSUInteger pivotIndex = NSNotFound;
    NSArray *viewControllersToMove =
        [ChattySplitViewController pivotableVCsFromViewControllers:_primaryVC.viewControllers
                                                          pivotIdx:&pivotIndex];
    _detailVC.viewControllers = viewControllersToMove;
    
    if (pivotIndex != NSNotFound) {
        // also, remove them from the primary
        _primaryVC.viewControllers = [_primaryVC.viewControllers subarrayWithRange:NSMakeRange(0, pivotIndex)];
    }
    
    if ([_detailVC.viewControllers count] == 0) {
        // In practice, this shouldn't happen, but it's worth covering this case.
        _detailVC.viewControllers = @[[NoContentController controllerWithNib]];
    }
    
    return _detailVC;
}

@end
