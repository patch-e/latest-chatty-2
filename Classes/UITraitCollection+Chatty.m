//
//  UITraitCollection+Chatty.m
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

#import "UITraitCollection+Chatty.h"

@implementation UITraitCollection (Chatty)
+ (BOOL)ch_isIpadInRegularSizeClass {
    UITraitCollection *collection = [UIApplication sharedApplication].keyWindow.traitCollection;
    return (collection.userInterfaceIdiom == UIUserInterfaceIdiomPad &&
            collection.horizontalSizeClass == UIUserInterfaceSizeClassRegular);
}
@end
