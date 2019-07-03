#import "RLYVibration.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The vibration behavior is one component of the information necessary to create a `RLYColorVibrationCommand`, describing
 the actions of the peripheral's vibration motor as a result of the command.

 The other component is `RLYColorBehavior`.
 */
@interface RLYVibrationBehavior : NSObject

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
 *  Initializes a vibration behavior.
 *
 *  @param count       The number of vibration pulses.
 *  @param power       The vibration motor power.
 *  @param durationOn  The duration of each vibration pulse. This is in units of
 *                     `RLYColorVibrationCommandMillisecondsPerUnit`.
 *  @param durationOff The amount of time to wait between each vibration pulse. This is in units of
 *                     `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
-(instancetype)initWithCount:(uint8_t)count
                       power:(RLYVibrationPower)power
                  durationOn:(uint8_t)durationOn
                 durationOff:(uint8_t)durationOff NS_DESIGNATED_INITIALIZER;

/**
 *  Returns a vibration behavior that performs no vibrations.
 */
+(instancetype)empty;

#pragma mark - Count

/**
 *  The number of vibration pulses.
 */
@property (nonatomic, readonly) uint8_t count;

#pragma mark - Power

/**
 *  The vibration motor power.
 */
@property (nonatomic, readonly) RLYVibrationPower power;

#pragma mark - Duration

/**
 *  The duration of each vibration pulse. This is in units of `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly) uint8_t durationOn;

/**
 *  The amount of time to wait between each vibration pulse. This is in units of `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly) uint8_t durationOff;

@end

NS_ASSUME_NONNULL_END
