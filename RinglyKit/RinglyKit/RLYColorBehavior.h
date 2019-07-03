#import "RLYColor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The color behavior is one component of the information necessary to create a `RLYColorVibrationCommand`, describing
 the actions of the peripheral's LED as a result of the command.
 
 The other component is `RLYVibrationBehavior`.
 */
@interface RLYColorBehavior : NSObject

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
 *  Initializes a color behavior.
 *
 *  @param count          The number of LED flashes to perform.
 *  @param color          The first color shown on the peripheral.
 *  @param secondaryColor The second color shown on the peripheral.
 *  @param delay          The amount of time to wait before flashing the LED. This is in units of
 *                        `RLYColorVibrationCommandMillisecondsPerUnit`.
 *  @param durationOn     The amount of time to flash the LED on. This is in units of
 *                        `RLYColorVibrationCommandMillisecondsPerUnit`.
 *  @param durationOff    The amount of time to leave the LED off between flashes. This is in units of
 *                        `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
-(instancetype)initWithCount:(uint8_t)count
                       color:(RLYColor)color
              secondaryColor:(RLYColor)secondaryColor
                       delay:(uint8_t)delay
                  durationOn:(uint8_t)durationOn
                 durationOff:(uint8_t)durationOff NS_DESIGNATED_INITIALIZER;

/**
 *  Returns a color behavior that performs no action.
 */
+(instancetype)empty;

#pragma mark - Properties
/**
 *  The number of LED flashes to perform.
 */
@property (nonatomic, readonly) uint8_t count;

/**
 *  The first color shown on the peripheral.
 */
@property (nonatomic, readonly) RLYColor color;

/**
 *  The second color shown on the peripheral.
 */
@property (nonatomic, readonly) RLYColor secondaryColor;

/**
 *  The amount of time to wait before flashing the LED. This is in units of `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly) uint8_t delay;

/**
 *  The amount of time to flash the LED on. This is in units of `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly) uint8_t durationOn;

/**
 *  The amount of time to leave the LED off between flashes. This is in units of `RLYColorVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly) uint8_t durationOff;

@end

NS_ASSUME_NONNULL_END
