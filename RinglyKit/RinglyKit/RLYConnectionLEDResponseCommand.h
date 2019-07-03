#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Enables or disables the manual connection LED response on a peripheral.
 */
RINGLYKIT_FINAL @interface RLYConnectionLEDResponseCommand : NSObject <RLYCommand>

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
 *  Initializes a connection LED response command.
 *
 *  @param enabled Whether or not the manual connection LED response should be enabled.
 */
-(instancetype)initWithEnabled:(BOOL)enabled NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  Whether or not the manual connection LED response should be enabled.
 */
@property (readonly, nonatomic, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
