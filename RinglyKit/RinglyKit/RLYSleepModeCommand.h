#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The default amount of time to use for sleep mode.
 */
RINGLYKIT_EXTERN uint8_t const RLYSleepModeCommandDefaultSleepTime;

/**
 *  To disable sleep mode, use this value.
 */
RINGLYKIT_EXTERN uint8_t const RLYSleepModeCommandDisabledSleepTime;

/**
 *  Alters the peripheral's sleep mode behavior. Sleep mode is triggered when the accelerometer does not detect any
 *  activity for the specified amount of time.
 */
RINGLYKIT_FINAL @interface RLYSleepModeCommand : NSObject <RLYCommand>

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
 *  Initializes a sleep mode command.
 *
 *  @param sleepTime The amount of time, in minutes, before the peripheral should go to sleep. To disable sleep mode,
 *                   use `RLYSleepModeCommandDisabledSleepTime`.
 */
-(instancetype)initWithSleepTime:(uint8_t)sleepTime NS_DESIGNATED_INITIALIZER;

#pragma mark - Sleep Time
/**
 *  The amount of time, in minutes, before the peripheral should go to sleep.
 */
@property (readonly, nonatomic) uint8_t sleepTime;

@end

NS_ASSUME_NONNULL_END
