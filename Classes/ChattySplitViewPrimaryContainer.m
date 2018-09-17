//
//  ChattySplitViewPrimaryContainer.m
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

#import "ChattySplitViewPrimaryContainer.h"

@interface ChattySplitViewControllerPrimaryContainer ()
@property (nonatomic, readwrite) UIButton *tabButton;
@property (nonatomic) UIViewController *primaryVC;

@property (nonatomic) NSArray<NSLayoutConstraint *> *regularConstraints;
@property (nonatomic) NSArray<NSLayoutConstraint *> *compactConstraints;
@property (nonatomic) NSArray<NSLayoutConstraint *> *collapsedConstraints;
@end

@implementation ChattySplitViewControllerPrimaryContainer
- (instancetype)initWithViewController:(UIViewController *)vc {
    if (self = [super init]) {
        _primaryVC = vc;
        _tabButtonVisible = YES;
        _tabButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = YES;
    _tabButton.translatesAutoresizingMaskIntoConstraints = NO;
    _primaryVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage *border = [[UIImage imageNamed:@"MenuBorder"] stretchableImageWithLeftCapWidth:0
                                                                              topCapHeight:100];
    UIImage *borderSelected = [[UIImage imageNamed:@"MenuBorderOut"] stretchableImageWithLeftCapWidth:0
                                                                                         topCapHeight:100];
    
    [_tabButton setBackgroundImage:border forState:UIControlStateNormal];
    [_tabButton setBackgroundImage:borderSelected forState:UIControlStateSelected];
    
    [self.view addSubview:_tabButton];
    [NSLayoutConstraint activateConstraints:@[
                                              [_tabButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
                                              [_tabButton.heightAnchor constraintEqualToAnchor:self.view.heightAnchor],
                                              [_tabButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                              [_tabButton.widthAnchor constraintEqualToConstant:25.0]
                                              ]];
    _tabButton.backgroundColor = [UIColor blackColor];
    
    [self addChildViewController:_primaryVC];
    [self.view addSubview:_primaryVC.view];
    
    self.regularConstraints = @[
                                [_primaryVC.view.leftAnchor constraintEqualToAnchor:_tabButton.rightAnchor],
                                [_primaryVC.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                [_primaryVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                [_primaryVC.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                ];
    
    self.collapsedConstraints = @[
                                [_primaryVC.view.leftAnchor constraintEqualToAnchor:_tabButton.rightAnchor],
                                [_primaryVC.view.widthAnchor constraintEqualToConstant:320.f],
                                [_primaryVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                [_primaryVC.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                ];
    
    self.compactConstraints = @[
                                [_primaryVC.view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
                                [_primaryVC.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
                                [_primaryVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                [_primaryVC.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                ];
    
    [NSLayoutConstraint activateConstraints:self.regularConstraints];
}

- (void)setCollapsed:(BOOL)collapsed {
    _collapsed = collapsed;
    _tabButton.selected = collapsed;
    
    if (collapsed) {
        [NSLayoutConstraint deactivateConstraints:_regularConstraints];
        [NSLayoutConstraint activateConstraints:_collapsedConstraints];
    }
    else {
        [NSLayoutConstraint deactivateConstraints:_collapsedConstraints];
        [NSLayoutConstraint activateConstraints:_regularConstraints];
    }
}

- (void)setTabButtonVisible:(BOOL)tabButtonVisible {
    if (_tabButtonVisible == tabButtonVisible) {
        return;
    }
    
    _tabButtonVisible = tabButtonVisible;
    _tabButton.hidden = !tabButtonVisible;
    
    NSArray<NSLayoutConstraint *> *toActivate = nil;
    NSArray<NSLayoutConstraint *> *toRemove = nil;
    if (tabButtonVisible) {
        toActivate = _collapsed ? _collapsedConstraints : _regularConstraints;
        toRemove = _compactConstraints;
    }
    else {
        toActivate = _compactConstraints;
        toRemove =  _collapsed ? _collapsedConstraints : _regularConstraints;
    }
    
    [NSLayoutConstraint deactivateConstraints:toRemove];
    [NSLayoutConstraint activateConstraints:toActivate];
}
@end
