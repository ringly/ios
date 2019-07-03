#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enables or disables the LED flash when the user taps the peripheral twice.
 */
RINGLYKIT_FINAL @interface RLYConnectionLEDCommand : NSObject <RLYCommand>

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
 *  Initializes a connection LED command.
 *
 *  @param enabled If the connection LED should be enabled, `YES`. Otherwise, `NO`.
 */
-(instancetype)initWithEnabled:(BOOL)enabled NS_DESIGNATED_INITIALIZER;

#pragma mark - Enabled
/**
 *  If `YES`, the LED flash will be enabled.
 */
@property (nonatomic, readonly, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
