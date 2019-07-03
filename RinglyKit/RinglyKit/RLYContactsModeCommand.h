#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates the supported contacts mode of a peripheral.
 */
typedef NS_ENUM(uint8_t, RLYContactsMode)
{
    /**
     *  Display notifications for all contacts, but display an additional color for enabled contacts.
     */
    RLYContactsModeAdditionalColor = 0,
    
    /**
     *  Only display notifications for enabled contacts.
     */
    RLYContactsModeContactsOnly = 1,
    
    /**
     *  Disable the contacts feature.
     */
    RLYContactsModeDisabled = 0xff
};

/**
 *  Alters the peripheral's contacts mode.
 */
RINGLYKIT_FINAL @interface RLYContactsModeCommand : NSObject <RLYCommand>

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
 *  Initializes a contacts mode command.
 *
 *  @param mode The contacts mode to use.
 */
-(instancetype)initWithMode:(RLYContactsMode)mode NS_DESIGNATED_INITIALIZER;

#pragma mark - Mode

/**
 *  The contacts mode to use.
 */
@property (nonatomic, readonly) RLYContactsMode mode;

@end

NS_ASSUME_NONNULL_END
