//
//  ComposeViewController.h
//  LatestChatty2
//
//  Created by Alex Wayne on 3/25/09.
//  Copyright 2009. All rights reserved.
//

#import "Post.h"
#import "Image.h"
#import "ModelListViewController.h"
#import "BrowserViewController.h"
#import "ChattySplitViewRootVCProtocol.h"

@interface ComposeViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, ImageSendingDelegate, UITextViewDelegate, ChattySplitViewRootVCProtocol> {
    NSInteger storyId;
	Post *post;
	
	NSDictionary *tagLookup;
	
    IBOutlet UILabel *composeLabel;
    IBOutlet UILabel *parentPostAuthor;
	IBOutlet UILabel *parentPostPreview;
	IBOutlet UITextView *postContent;
    IBOutlet UIButton *imageButton;
    IBOutlet UIView *tagView;
    IBOutlet UIView *innerTagView;
    IBOutlet UIScrollView *innerTagScrollView;
	
	IBOutlet UIView *activityView;
	IBOutlet UILabel *activityText;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UIProgressView *uploadBar;
    
    NSRange selection;
}

@property (assign) NSInteger storyId;
@property (strong) Post *post;

- (id)initWithStoryId:(NSInteger)aStoryId post:(Post *)aPost;
- (void)makePost;
- (UIProgressView *)showActivityIndicator:(BOOL)progressViewType;

- (IBAction)showImagePicker;
- (IBAction)tag:(id)sender;
- (IBAction)closeTagView;

- (void)sendPost;

@end
