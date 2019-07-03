#import <Foundation/Foundation.h>

/**
 *  Dispatches a block to the main thread, after specified time interval.
 *
 *  @param after The time interval to wait.
 *  @param block The block to dispatch.
 */
FOUNDATION_EXTERN void RLYDispatchAfterMain(NSTimeInterval after, dispatch_block_t block);

#ifdef DEBUG
FOUNDATION_EXTERN NSString *RLYJSONString(id JSONObject);
#endif
