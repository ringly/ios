#import "RLYActivityTrackingDate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Steps are stored as an eight-bit unsigned integer, which is the representation used on the peripheral itself.
 */
typedef uint8_t RLYActivityTrackingSteps;

/**
 *  A snapshot of a minute's worth of activity tracking data.
 */
RINGLYKIT_FINAL @interface RLYActivityTrackingUpdate : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable, use the designated initializer instead.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable, use the designated initializer instead.
 */
-(instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes an activity tracking data object.
 *
 *  @param date         The date associated with the data.
 *  @param walkingSteps The number of walking steps.
 *  @param runningSteps The number of running steps.
 */
-(instancetype)initWithDate:(RLYActivityTrackingDate*)date
               walkingSteps:(RLYActivityTrackingSteps)walkingSteps
               runningSteps:(RLYActivityTrackingSteps)runningSteps NS_DESIGNATED_INITIALIZER;

#pragma mark - Date

/**
 *  The date associated with the data.
 */
@property (nonatomic, readonly, strong) RLYActivityTrackingDate *date;

#pragma mark - Steps

/**
 *  The number of walking steps.
 */
@property (nonatomic, readonly) RLYActivityTrackingSteps walkingSteps;

/**
 *  The number of running steps.
 */
@property (nonatomic, readonly) RLYActivityTrackingSteps runningSteps;

/**
 *  The total number of steps, a combination of `walkingSteps` and `runningSteps`.
 */
@property (nonatomic, readonly) NSInteger steps;

@end

NS_ASSUME_NONNULL_END
