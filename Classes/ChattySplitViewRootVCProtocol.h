//
//  ChattySplitViewRootVCProtocol.h
//  LatestChatty2
//
//  Created by Jeffrey Forbes on 9/16/18.
//

NS_ASSUME_NONNULL_BEGIN

/**
 *  This is a protocol that exists for View Controllers to move across the Primary/Detail boundary. If the below
 *  method returns YES, it can be used as a pivot point to move view controllers across in the event of a
 *  split screen event.
 */
@protocol ChattySplitViewRootVCProtocol <NSObject>
- (BOOL)canActAsRootForSplitViewEvents;
@end

NS_ASSUME_NONNULL_END
