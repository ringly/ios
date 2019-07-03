#import <Foundation/Foundation.h>

/**
 *  A utility for classes with a variable number of "observer" objects, which will typically conform to a protocol
 *  defined alongside that class.
 *
 *  This can be considered a form of delegation, with an arbitrary number of subscribers. Observers are weakly
 *  referenced, so they will be removed automatically if deallocated.
 */
@interface RLYObservers : NSObject

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Observers
/** @mark Observers */

/**
 *  Adds an observer.
 *
 *  @param observer The observer to add.
 */
-(void)addObserver:(id)observer;

/**
 *  Removes an observer.
 *
 *  @param observer The observe to remove.
 */
-(void)removeObserver:(id)observer;

/**
 *  Enumerates the observers.
 *
 *  @param block A block, which will recieve each observer.
 */
-(void)enumerateObservers:(void(^)(id observer))block;

NS_ASSUME_NONNULL_END

@end

/**
 *  Includes the boilerplate implementation code for a class using `RLYObservable`.
 *
 *  @param PROTOCOL_TYPE The protocol that observer implementations conform to.
 *  @param TARGET        The target of observer messages (i.e. the ivar name).
 */
#define _RLY_OBSERVABLE_BOILERPLATE(PROTOCOL_TYPE, TARGET) \
-(void)addObserver:(nonnull id<PROTOCOL_TYPE>)observer\
{\
    [TARGET addObserver:observer];\
}\
-(void)removeObserver:(nonnull id<PROTOCOL_TYPE>)observer\
{\
    [TARGET removeObserver:observer];\
}\
