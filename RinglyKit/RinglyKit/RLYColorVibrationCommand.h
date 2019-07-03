#import "RLYColorBehavior.h"
#import "RLYCommand.h"
#import "RLYVibrationBehavior.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The number of milliseconds in each time unit used by `RLYColorVibrationCommand` properties.
 */
RINGLYKIT_EXTERN NSUInteger const RLYColorVibrationCommandMillisecondsPerUnit;

/**
 *  A command that instructs the peripheral to vibrate and/or flash its LED.
 */
RINGLYKIT_FINAL @interface RLYColorVibrationCommand : NSObject <RLYCommand>

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
 *  Initializes a color & vibration command.
 *
 *  @param colorBehavior     The color behavior for the command.
 *  @param vibrationBehavior The vibration behavior for the command.
 */
-(instancetype)initWithColorBehavior:(RLYColorBehavior*)colorBehavior
                   vibrationBehavior:(RLYVibrationBehavior*)vibrationBehavior NS_DESIGNATED_INITIALIZER;

/**
 *  Creates a command by specifying the colors and vibration pattern.
 *
 *  @param color           The primary color to show on the peripheral's LED.
 *  @param secondaryColor  The secondary color to show on the peripheral's LED.
 *  @param vibration       The vibration pattern to perform on the device.
 */
+(instancetype)commandWithColor:(RLYColor)color
                 secondaryColor:(RLYColor)secondaryColor
                      vibration:(RLYVibration)vibration;

/**
 *  Creates a command by specifying the colors and vibration pattern.
 *
 *  @param color           The primary color to show on the peripheral's LED.
 *  @param secondaryColor  The secondary color to show on the peripheral's LED.
 *  @param vibration       The vibration pattern to perform on the device.
 *  @param LEDFadeDuration The number of milliseconds it should take for the LED to fade on and off.
 */
+(instancetype)commandWithColor:(RLYColor)color
                 secondaryColor:(RLYColor)secondaryColor
                      vibration:(RLYVibration)vibration
                LEDFadeDuration:(uint8_t)LEDFadeDuration;

/**
 *  Creates a command with the azure color and the specified vibration.
 *
 *  @param vibration The vibration pattern to use.
 */
+(instancetype)commandWithAzureColorAndVibration:(RLYVibration)vibration;

#pragma mark - Components

/**
 *  The command's color behavior.
 */
@property (nonatomic, readonly, strong) RLYColorBehavior *colorBehavior;

/**
 *  The command's vibration behavior.
 */
@property (nonatomic, readonly, strong) RLYVibrationBehavior *vibrationBehavior;

@end

NS_ASSUME_NONNULL_END
