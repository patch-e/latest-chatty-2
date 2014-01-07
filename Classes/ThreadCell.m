//
//  ThreadCell.m
//  LatestChatty2
//
//  Created by Alex Wayne on 3/18/09.
//  Copyright 2009. All rights reserved.
//

#import "ThreadCell.h"

@implementation ThreadCell

@synthesize storyId;
@synthesize rootPost;

+ (CGFloat)cellHeight {
	return 70.0;
}

- (id)init {
	self = [super initWithNibName:@"ThreadCell" bundle:nil];
    
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	// Set text labels
	author.text = rootPost.author;

    // if this is a search result or the user doesn't want markup in chatty thread cells, use the preview
    // otherwise, generate an attributed string using the threadMarkup property on the app delegate with the body of the post
    if ([rootPost.body isEqual:[NSNull null]] || ![defaults boolForKey:@"chattyTags"]) {
        preview.text = rootPost.preview;
    } else {
        NSString *formattedBody = [NSString stringWithFormat:[LatestChatty2AppDelegate delegate].chattyMarkup, rootPost.body];
        // need to handle some certain cases in the body markup:
        // replace breaks with spaces
        formattedBody = [formattedBody stringByReplacingOccurrencesOfString: @"<br />" withString:@" "];
        // replace anchors which aren't being attributed correctly in the attributed string with a span tag and a new
        // jt_anchor class that is styled like an anchor
        formattedBody = [formattedBody stringByReplacingOccurrencesOfString: @"<a " withString:@"<span class=\"jt_anchor\""];
        
        // iOS 7-only way of creating attributed stings from HTML
        NSAttributedString *test = [[NSAttributedString alloc] initWithData:[formattedBody dataUsingEncoding:NSUTF8StringEncoding]
                                                                    options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                              NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]}
                                                         documentAttributes:nil
                                                                      error:nil];
        preview.attributedText = test;
    }
    
	date.text = [Post formatDate:rootPost.date];
    
    // force white text color on highlight
    author.highlightedTextColor = [UIColor whiteColor];
    date.highlightedTextColor = [UIColor whiteColor];
    replyCount.highlightedTextColor = [UIColor whiteColor];
    preview.highlightedTextColor = [UIColor whiteColor];
	
	NSString* newPostText = nil;
	if (rootPost.newReplies) {
		newPostText = [NSString stringWithFormat:@"+%d", rootPost.newReplies];
		replyCount.text = [NSString stringWithFormat:@"%i (%@)", rootPost.replyCount, newPostText];
	} else {
        replyCount.text = [NSString stringWithFormat:@"%i", rootPost.replyCount];
    }
    
	// Set background to a light color if the user is the root poster
	if ([rootPost.author.lowercaseString isEqualToString:[defaults stringForKey:@"username"].lowercaseString]) {
        self.backgroundColor = [UIColor lcCellParticipantColor];
	} else {
        self.backgroundColor = [UIColor lcCellNormalColor];
	}
	
	// Set side color stripe for the post category
	categoryStripe.backgroundColor = rootPost.categoryColor;
	
	// Detect participation
    BOOL foundParticipant = NO;
	for (NSDictionary *participant in rootPost.participants) {
		NSString *username = [defaults stringForKey:@"username"].lowercaseString;
        NSString *participantName = [participant objectForKey:@"username"];
        participantName = participantName.lowercaseString;
        
		if (username && ![username isEqualToString:@""] && [participantName isEqualToString:username]) {
            foundParticipant = YES;
        }
    }
    
    if (foundParticipant) {
        replyCount.textColor = [UIColor lcBlueParticipantColor];
    } else {
        replyCount.textColor = [UIColor lcLightGrayTextColor];
    }
    
    // Choose which timer icon to show based on post date and participation indication
    timerIcon.image = [Post imageForPostExpiration:rootPost.date withParticipant:foundParticipant];
}

- (BOOL)showCount {
	return !replyCount.hidden;
}

- (void)setShowCount:(BOOL)shouldShowCount {
	replyCount.hidden = !shouldShowCount;
}

@end
