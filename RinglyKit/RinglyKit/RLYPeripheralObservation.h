#import "RLYPeripheralObserver.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Allows peripheral observers to be added and removed.
 */
@protocol RLYPeripheralObservation <NSObject>

#pragma mark - Observers
/**
 *  Adds an observer.
 *
 *  @param observer The observer to add.
 */
-(void)addObserver:(id<RLYPeripheralObserver>)observer NS_SWIFT_NAME(add(observer:));

/**
 *  Removes an observer.
 *
 *  @param observer The observer to remove.
 */
-(void)removeObserver:(id<RLYPeripheralObserver>)observer NS_SWIFT_NAME(remove(observer:));

@end

NS_ASSUME_NONNULL_END
