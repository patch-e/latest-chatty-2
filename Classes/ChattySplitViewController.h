//
//  ChattySplitViewController.h
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

/**
 *  A subclass of UISplitViewController that handles the expansion and collapse of viewcontrollers as
 *  trait collections change. View controllers move from primary to detail depending on their adoption
 *  of @p ChattySplitViewRootVCProtocol, which dictates the pivot point from which view controllers
 *  will move.
 */
@interface ChattySplitViewController : UISplitViewController
- (instancetype)initWithPrimary:(UINavigationController *)primaryVC
                         detail:(UINavigationController *)detailVC;
- (void)forceCollapse;

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
