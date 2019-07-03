#import <Foundation/Foundation.h>

@interface NSArray (Ringly)

#pragma mark - Array Functional
/** @name Array Functional */

/**
 *  Passes increasing indices to `block` and builds an array of the return values.
 *
 *  @param count The desired count of the array. The highest `index` value will be `count - 1`.
 *  @param block The mapping block, which will receive increasing indices.
 */
+(NSArray*)rly_mapToCount:(NSUInteger)count withBlock:(id(^)(NSUInteger index))block;

@end
