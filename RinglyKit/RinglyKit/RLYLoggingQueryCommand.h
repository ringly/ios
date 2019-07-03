#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates the queries supported by the logging query command.
 */
typedef NS_ENUM(uint8_t, RLYLoggingQuery)
{
    /**
     *  Frequency Channel - Response will be FREQUENCY register under NRF_RADIO as outlined in the nRF51822 Series Reference Manual.
     */
    RLYLoggingQueryFrequency = 1,
    
    /**
     *  Reset reason - Response will be the RESETREAS register under NRF_POWER as outlined in the nRF51822 Series Reference Manual
     */
    RLYLoggingQueryResetReason = 2,
    
    /**
     *  Toggle RSSI on/off
     */
    RLYLoggingQueryFreqRSSI = 3,
    
    /**
     *  The time in milliseconds since the last time the peripheral was reset.
     */
    RLYLoggingQueryTimeSinceBootup = 4,
    
    /**
     *  Stat Pin Value (1 = 3V, 0 = 0V)
     */
    RLYLoggingQueryStatePinValue = 5,
    
    /**
     *  Charge 5V Pin value (1 = 5V, 0 = 0V)
     */
    RLYLoggingQueryChargePinValue = 6,
    
    /**
     *  Requests burn test data.
     */
    RLYLoggingQueryBurnTestData = 7
};

/**
 *  Sends a logging query command to the peripheral.
 *
 *  This data will be notified on characteristic FFE1 on Service FFE0.
 */
RINGLYKIT_FINAL @interface RLYLoggingQueryCommand : NSObject <RLYCommand>

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
 *  Creates a logging query command.
 *
 *  @param query The data to query.
 */
-(instancetype)initWithQuery:(RLYLoggingQuery)query NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The data type to request.
 */
@property (nonatomic, readonly) RLYLoggingQuery query;

@end

NS_ASSUME_NONNULL_END
