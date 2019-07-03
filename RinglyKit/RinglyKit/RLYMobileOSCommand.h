#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates the mobile OS types supported by the peripheral.
 */
typedef NS_ENUM(uint8_t, RLYMobileOSType)
{
    /**
     *  No specific mobile OS.
     */
    RLYMobileOSTypeNone,
    
    /**
     *  iOS.
     */
    RLYMobileOSTypeiOS = 1,
    
    /**
     *  Android.
     */
    RLYMobileOSTypeAndroid = 2
};

/**
 *  Allows the application to inform the peripheral of the mobile OS that it is connected to.
 */
RINGLYKIT_FINAL @interface RLYMobileOSCommand : NSObject <RLYCommand>

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
 *  Initializes a command with the specified mobile OS type.
 *
 *  If the peripheral this command is sent to is in factory mode, it will be taken out of factory mode.
 *
 *  @param mobileOSType The mobile OS type.
 */
-(instancetype)initWithType:(RLYMobileOSType)mobileOSType;

/**
 *  Initializes a command with the specified mobile OS type and factory mode.
 *
 *  @param mobileOSType The mobile OS type.
 */
-(instancetype)initWithType:(RLYMobileOSType)mobileOSType factoryMode:(BOOL)factoryMode NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The mobile OS type for this command.
 */
@property (nonatomic, readonly) RLYMobileOSType mobileOSType;

/**
 *  If `YES`, a peripheral sent this command will be placed (or stay) in factory mode. If `NO`, it will be taken out of
 *  factory mode.
 */
@property (nonatomic, readonly) BOOL factoryMode;

@end

NS_ASSUME_NONNULL_END
