#import "RLYColorVibrationCommand.h"
#import "RLYCommand.h"

NS_ASSUME_NONNULL_BEGIN

/// The number of milliseconds per uinit of `RLYDisconnectVibrationCommand`'s duration properties.
RINGLYKIT_EXTERN NSUInteger const RLYDisconnectVibrationCommandMillisecondsPerUnit;

/**
 *  Changes the "disconnect vibration" behavior of a peripheral.
 */
RINGLYKIT_FINAL @interface RLYDisconnectVibrationCommand : NSObject <RLYCommand>

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
 Initializes a disconnect vibration command.

 @param vibrationBehavior The vibration behavior to use. Duration units are in terms of
                          `RLYDisconnectVibrationCommandMillisecondsPerUnit`.
 @param waitTime The amount of seconds to wait after disconnect before triggering the vibration. Setting this value to
                 `0` or a number `>= 240` will disable the disconnect vibration.
 @param backoffTime The backoff time, in minutes.
 */
-(instancetype)initWithVibrationBehavior:(RLYVibrationBehavior*)vibrationBehavior
                                waitTime:(uint8_t)waitTime
                             backoffTime:(uint8_t)backoffTime NS_DESIGNATED_INITIALIZER;

/**
 Initializes a disconnect vibration command with default values.

 @param enabled Whether the command should enable or disable disconnect vibrations.
 */
-(instancetype)initWithDefaultsForEnabled:(BOOL)enabled;

#pragma mark - Properties

/**
 *  The vibration behavior to use. Duration units are in terms of `RLYDisconnectVibrationCommandMillisecondsPerUnit`.
 */
@property (nonatomic, readonly, strong) RLYVibrationBehavior *vibrationBehavior;

/**
 *  The amount of seconds to wait after disconnect before triggering the vibration.
 *
 *  Setting this value to `0` or a number `>= 240` will disable the disconnect vibration.
 */
@property (nonatomic, readonly) uint8_t waitTime;

/**
 *  The backoff time, in minutes.
 */
@property (nonatomic, readonly) uint8_t backoffTime;

@end

NS_ASSUME_NONNULL_END
