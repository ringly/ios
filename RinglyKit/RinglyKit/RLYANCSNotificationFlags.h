#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Supported values for the `flagsData` property of `RLYANCSNotification`.
 */
typedef NS_OPTIONS(uint8_t, RLYANCSNotificationFlags)
{
    /**
     *  The notification is silent.
     */
    RLYANCSNotificationFlagsSilent = 1 << 0,
    
    /**
     *  The notification is important.
     */
    RLYANCSNotificationFlagsImportant = 1 << 1,
    
    /**
     *  The notification is pre-existing.
     */
    RLYANCSNotificationFlagsPreExisting = 1 << 2,
    
    /**
     *  The notification has a postive action.
     */
    RLYANCSNotificationFlagsPositiveAction = 1 << 3,
    
    /**
     *  The notification has a negative action.
     */
    RLYANCSNotificationFlagsNegativeAction = 1 << 4
};

/**
 Wraps a `RLYANCSNotificationFlags` value in an Objective-C object.
 */
RINGLYKIT_FINAL @interface RLYANCSNotificationFlagsValue : NSObject

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
 *  Initializes an ANCS notification flags value.
 *
 *  @param flags The flags to use.
 */
-(instancetype)initWithFlags:(RLYANCSNotificationFlags)flags NS_DESIGNATED_INITIALIZER;

#pragma mark - Flags

/**
 *  The flags stored by this value.
 */
@property (nonatomic, readonly) RLYANCSNotificationFlags flags;

@end

NS_ASSUME_NONNULL_END
