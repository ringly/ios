#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Enables or disables the ANCS timeout alert on a peripheral.
 */
RINGLYKIT_FINAL @interface RLYANCSTimeoutAlertCommand : NSObject <RLYCommand>

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
 *  Initializes an ANCS timeout alert command.
 *
 *  @param enabled Whether or not the ANCS timeout alert should be enabled.
 */
-(instancetype)initWithEnabled:(BOOL)enabled NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  Whether or not the ANCS timeout alert should be enabled.
 */
@property (readonly, nonatomic, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
