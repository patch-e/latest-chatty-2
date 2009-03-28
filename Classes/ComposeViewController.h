//
//  ComposeViewController.h
//  LatestChatty2
//
//  Created by Alex Wayne on 3/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

@interface ComposeViewController : UIViewController {
  NSInteger storyId;
  Post *post;
  
  NSDictionary *tagLookup;
  
  IBOutlet UILabel *parentPostPreview;
  IBOutlet UITextView *postContent;
}

@property (assign) NSInteger storyId;
@property (retain) Post *post;

- (id)initWithStoryId:(NSInteger)aStoryId post:(Post *)aPost;

- (IBAction)showTagButtons;
- (IBAction)showImagePicker;
- (IBAction)tag:(id)sender;

- (IBAction)dismiss;
- (IBAction)sendPost;

@end
