//
//  Categories.m
//  LatestChatty2
//
//  Created by patch-e on 5/28/13.
//
//

#import "Categories.h"
#import "HTMLEscaper.h"

// String categories
@implementation NSString (StringAdditions)

- (NSString *)stringByUnescapingHTML {
    HTMLEscaper *escaper = [[HTMLEscaper alloc] init];
    NSString *unescapedString = [escaper unescapeEntitiesInString:self];
    
    return unescapedString;
}

+ (NSString *)rgbaFromUIColor:(UIColor *)color {
    return [NSString stringWithFormat:@"rgba(%d,%d,%d,%f)",
            (int)(CGColorGetComponents(color.CGColor)[0]*255.0),
            (int)(CGColorGetComponents(color.CGColor)[1]*255.0),
            (int)(CGColorGetComponents(color.CGColor)[2]*255.0),
            CGColorGetComponents(color.CGColor)[3]];
}
+ (NSString *)hexFromUIColor:(UIColor *)color {
    return [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)(CGColorGetComponents(color.CGColor)[0]*255.0),
            (int)(CGColorGetComponents(color.CGColor)[1]*255.0),
            (int)(CGColorGetComponents(color.CGColor)[2]*255.0)];
}

@end

@implementation UIColor (ColorAdditions)

// Common colors
+ (UIColor *)lcAuthorColor {
    return [UIColor colorWithRed:245.0/255.0 green:228.0/255.0 blue:157.0/255.0 alpha:1.0];
}

+ (UIColor *)lcBlueColor {
    return [UIColor colorWithRed:119.0/255.0 green:197.0/255.0 blue:254.0/255.0 alpha:1.0];
}

+ (UIColor *)lcLightGrayTextColor {
    return [UIColor colorWithRed:176.0/255.0 green:180.0/255.0 blue:184.0/255.0 alpha:1.0];
}

+ (UIColor *)lcDarkGrayTextColor {
    return [UIColor colorWithRed:183.0/255.0 green:187.0/255.0 blue:194.0/255.0 alpha:1.0];
}

+ (UIColor *)lcTextShadowColor {
    return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (UIColor *)lcOverlayColor {
    return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (UIColor *)lcIOS7BlueColor {
    return [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
}

+ (UIColor *)lcIOS7BlueColorHighlight {
    return [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:0.25];
}

// Table cell colors
+ (UIColor *)lcCellNormalColor {
    return [UIColor colorWithRed:54.0/255.0 green:54.0/255.0 blue:58.0/255.0 alpha:1.0];
}

+ (UIColor *)lcCellParticipantColor {
    return [UIColor colorWithRed:40.0/255.0 green:59.0/255.0 blue:82.0/255.0 alpha:1.0];
}

+ (UIColor *)lcGroupedCellColor {
    return [UIColor colorWithRed:47.0/255.0 green:48.0/255.0 blue:51.0/255.0 alpha:1.0];
}

+ (UIColor *)lcGroupedCellLabelColor {
    return [UIColor colorWithRed:172.0/255.0 green:172.0/255.0 blue:173.0/255.0 alpha:1.0];
}

+ (UIColor *)lcGroupedTitleColor {
    return [UIColor colorWithRed:121.0/255.0 green:122.0/255.0 blue:128.0/255.0 alpha:1.0];
}

+ (UIColor *)lcGroupedSeparatorColor {
    return [UIColor colorWithRed:27.0/255.0 green:27.0/255.0 blue:29.0/255.0 alpha:1.0];
}

+ (UIColor *)lcSeparatorColor {
    return [UIColor colorWithRed:40.0/255.0 green:41.0/255.0 blue:44.0/255.0 alpha:0.8];
}

+ (UIColor *)lcSeparatorDarkColor {
    return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:0.8];
}

+ (UIColor *)lcSelectionBlueColor {
    return [UIColor lcIOS7BlueColor];
}

+ (UIColor *)lcSelectionGrayColor {
    return [UIColor colorWithRed:53.0/255.0 green:53.0/255.0 blue:57.0/255.0 alpha:1.0];
}

+ (UIColor *)lcTableBackgroundColor {
    return [UIColor colorWithRed:40.0/255.0 green:41.0/255.0 blue:44.0/255.0 alpha:1.0];
}

+ (UIColor *)lcTableBackgroundDarkColor {
    return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
}

+ (UIColor *)lcRepliesTableBackgroundColor {
    return [UIColor colorWithRed:28.0/255.0 green:28.0/255.0 blue:30.0/255.0 alpha:1.0];
}

+ (UIColor *)lcRepliesTableBackgroundDarkColor {
    return [UIColor blackColor];
}

+ (UIColor *)lcPullToRefreshBackgroundColor {
    return [UIColor colorWithRed:47.0/255.0 green:47.0/255.0 blue:50.0/255.0 alpha:1.0];
}

// Post expiration progress colors
+ (UIColor *)lcExpiredColor {
    return [UIColor colorWithRed:131.0/255.0 green:41.0/255.0 blue:43.0/255.0 alpha:0.50];
}

+ (UIColor *)lcExpirationOnTopicColor {
    return [UIColor colorWithRed:78.0/255.0 green:79.0/255.0 blue:83.0/255.0 alpha:0.50];
}

+ (UIColor *)lcExpirationInformativeColor {
    return [UIColor colorWithRed:6.0/255.0 green:82.0/255.0 blue:112.0/255.0 alpha:1.0];
}

+ (UIColor *)lcExpirationOffTopicColor {
    return [UIColor colorWithRed:126.0/255.0 green:127.0/255.0 blue:130.0/255.0 alpha:1.0];
}

+ (UIColor *)lcExpirationStupidColor {
    return [UIColor colorWithRed:10.0/255.0 green:80.0/255.0 blue:43.0/255.0 alpha:1.0];
}

+ (UIColor *)lcExpirationPoliticalColor {
    return [UIColor colorWithRed:116.0/255.0 green:77.0/255.0 blue:34.0/255.0 alpha:1.0];
}

+ (UIColor *)lcExpirationNotWorkSafeColor {
    return [UIColor colorWithRed:104.0/255.0 green:28.0/255.0 blue:31.0/255.0 alpha:1.0];
}

// Category colors
+ (UIColor *)lcInformativeColor {
    return [UIColor colorWithRed:27.0/255.0 green:110.0/255.0 blue:151.0/255.0 alpha:1.0];
}

+ (UIColor *)lcOffTopicColor {
    return [UIColor colorWithRed:103.0/255.0 green:104.0/255.0 blue:110.0/255.0 alpha:1.0];
}

+ (UIColor *)lcStupidColor {
    return [UIColor colorWithRed:27.0/255.0 green:103.0/255.0 blue:50.0/255.0 alpha:1.0];
}

+ (UIColor *)lcPoliticalColor {
    return [UIColor colorWithRed:151.0/255.0 green:100.0/255.0 blue:29.0/255.0 alpha:1.0];
}

+ (UIColor *)lcNotWorkSafeColor {
    return [UIColor colorWithRed:131.0/255.0 green:41.0/255.0 blue:43.0/255.0 alpha:1.0];
}

// Reply text colors
+ (UIColor *)lcReplyLevel1Color {
    return [UIColor colorWithWhite:255.0 alpha:0.95];
}

+ (UIColor *)lcReplyLevel2Color {
    return [UIColor colorWithWhite:255.0 alpha:0.90];
}

+ (UIColor *)lcReplyLevel3Color {
    return [UIColor colorWithWhite:255.0 alpha:0.85];
}

+ (UIColor *)lcReplyLevel4Color {
    return [UIColor colorWithWhite:255.0 alpha:0.80];
}

+ (UIColor *)lcReplyLevel5Color {
    return [UIColor colorWithWhite:255.0 alpha:0.75];
}

// Settings colors
+ (UIColor *)lcSwitchOnColor {
    return [UIColor colorWithRed:6.0/255.0 green:109.0/255.0 blue:200.0/255.0 alpha:1.0];
}

+ (UIColor *)lcSwitchOffColor {
    return [UIColor colorWithRed:40.0/255.0 green:40.0/255.0 blue:43.0/255.0 alpha:1.0];
}

+ (UIColor *)lcSliderThumbColor {
    return [UIColor colorWithRed:66.0/255.0 green:67.0/255.0 blue:70.0/255.0 alpha:1.0];
}

@end

@implementation NSDictionary (DictionaryAdditions)

+ (NSDictionary *)titleTextAttributesDictionary {
//    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
//    [shadow setShadowColor:[UIColor lcTextShadowColor]];
//    [shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
    
    return @{NSForegroundColorAttributeName:[UIColor whiteColor]};
//             NSShadowAttributeName:shadow};
}

+ (NSDictionary *)whiteTextAttributesDictionary {
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor lcTextShadowColor]];
    [shadow setShadowOffset:CGSizeMake(0.0, 1.0)];
    
    return @{NSForegroundColorAttributeName:[UIColor whiteColor],
             NSShadowAttributeName:shadow};
}

+ (NSDictionary *)blueTextAttributesDictionary {
    return @{NSForegroundColorAttributeName:[UIColor lcIOS7BlueColor]};
}

+ (NSDictionary *)grayTextAttributesDictionary {
//    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
//    [shadow setShadowColor:[UIColor lcTextShadowColor]];
//    [shadow setShadowOffset:CGSizeMake(0.0, 1.0)];
    
    return @{NSForegroundColorAttributeName:[UIColor lcDarkGrayTextColor]};
//             NSShadowAttributeName:shadow};
}

+ (NSDictionary *)textShadowAttributesDictionary {
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor lcTextShadowColor]];
    [shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
    
    return @{NSShadowAttributeName:shadow};
}

@end

//@implementation UIImage(ImageAdditions)

//+ (UIImage *)navbarBgImage {
//    return [[UIImage imageNamed:@"navbar_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 8, 1, 8)];
//}
//
//+ (UIImage *)navbarBgLandscapeImage {
//    return [[UIImage imageNamed:@"navbar_bg_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 8, 1, 8)];
//}
//
//+ (UIImage *)toolbarBgImage {
//    return [[UIImage imageNamed:@"toolbar_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
//}
//
//+ (UIImage *)backButtonImage {
//    return [[UIImage imageNamed:@"button_back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 6)];
//}
//
//+ (UIImage *)backButtonHighlightImage {
//    return [[UIImage imageNamed:@"button_back_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 6)];
//}
//
//+ (UIImage *)backButtonLandscapeImage {
//    return [[UIImage imageNamed:@"button_back_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 6)];
//}
//
//+ (UIImage *)backButtonHighlightLandscapeImage {
//    return [[UIImage imageNamed:@"button_back_highlight_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 6)];
//}
//
//+ (UIImage *)barButtonNormalImage {
//    return [[UIImage imageNamed:@"button_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}
//
//+ (UIImage *)barButtonNormalHighlightImage {
//    return [[UIImage imageNamed:@"button_normal_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}
//
//+ (UIImage *)barButtonNormalLandscapeImage {
//    return [[UIImage imageNamed:@"button_normal_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}
//
//+ (UIImage *)barButtonNormalHighlightLandscapeImage {
//    return [[UIImage imageNamed:@"button_normal_highlight_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}
//
//+ (UIImage *)barButtonDoneImage {
//    return [[UIImage imageNamed:@"button_done"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}
//
//+ (UIImage *)barButtonDoneLandscapeImage {
//    return [[UIImage imageNamed:@"button_done_landscape"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
//}

//@end