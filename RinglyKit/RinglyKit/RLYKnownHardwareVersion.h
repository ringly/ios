#import <CoreBluetooth/CoreBluetooth.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// Enumerates the hardware versions that we are aware of.
typedef NS_ENUM(NSInteger, RLYKnownHardwareVersion)
{
    /// Version 1 ("Park").
    RLYKnownHardwareVersion1,

    /// Version 2 ("Madison").
    RLYKnownHardwareVersion2
};

/**
 Returns a version string that is valid for the specified known hardware version.

 @param version The known hardware version.
 */
FOUNDATION_EXTERN NSString *RLYKnownHardwareVersionDefaultVersionString(RLYKnownHardwareVersion version);

/**
 Returns the solicited service UUID for a peripheral with the specified hardware version in recovery mode.

 @param version The known hardware version.
 */
FOUNDATION_EXTERN CBUUID *RLYKnownHardwareVersionRecoverySolicitedServiceUUID(RLYKnownHardwareVersion version);

/**
 *  Wraps a known hardware version in an object.
 */
RINGLYKIT_FINAL @interface RLYKnownHardwareVersionValue : NSObject

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
 *  Initializes a value wrapper.
 *
 *  @param value The value to wrap.
 */
-(instancetype)initWithValue:(RLYKnownHardwareVersion)value NS_DESIGNATED_INITIALIZER;

#pragma mark - Value

/**
 *  The wrapped value.
 */
@property (nonatomic, readonly) RLYKnownHardwareVersion value;

@end

NS_ASSUME_NONNULL_END
