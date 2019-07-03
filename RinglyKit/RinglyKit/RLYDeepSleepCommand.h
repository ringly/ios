#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Places the peripheral into hibernate mode, after which it must be placed in a charger.
 */
RINGLYKIT_FINAL @interface RLYDeepSleepCommand : NSObject <RLYCommand>

@end

NS_ASSUME_NONNULL_END
