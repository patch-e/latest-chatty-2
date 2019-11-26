//
//  ChattySplitViewPrimaryContainer.h
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChattySplitViewControllerPrimaryContainer: UIViewController

// A button running up and down the left-hand side of the container, for showing/hiding this container.
// The actual hide/show logic happens upstream.
@property (nonatomic, readonly) UIButton *tabButton;

// Updates the tab indicator to indicate whether or not the view container is collapsed.
@property (nonatomic) BOOL collapsed;

// Sets whether or not the toggle should be visible.
@property (nonatomic) BOOL tabButtonVisible;

/**
 *  Created an instance of the container, adding the supplied viewcontroller as a subview.
 */
- (instancetype)initWithViewController:(UIViewController *)vc;

/**
 *  Unavailable
 */
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibName NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
