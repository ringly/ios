#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A container for the services provided by a Ringly peripheral.
 */
@interface RLYPeripheralServices : NSObject

#pragma mark - Creation

/**
 *  Creates a peripheral services object from an array of Core Bluetooth services, if possible.
 *
 *  @param services The array of Core Bluetooth services to convert into an array of services.
 *  @param error    An error pointer, which will be set if the conversion fails.
 *
 *  @return If the conversion is successful, a peripheral services object, otherwise, `nil`.
 */
+(nullable instancetype)peripheralServicesWithServices:(NSArray<CBService*>*)services error:(NSError**)error;

#pragma mark - Services

/**
 *  Includes characteristics for Ringly-specific commands and notifications.
 */
@property (nonatomic, readonly, strong) CBService *ringlyService;

/**
 *  Includes characteristics that provide battery information.
 */
@property (nonatomic, readonly, strong) CBService *batteryService;

/**
 *  Includes characteristics that provide general device information.
 */
@property (nonatomic, readonly, strong) CBService *deviceInformationService;

/**
 *  Includes characteristics that provide logging.
 */
@property (nullable, nonatomic, readonly, strong) CBService *loggingService;

/**
 *  Includes characteristics that provide access to activity tracking data.
 */
@property (nullable, nonatomic, readonly, strong) CBService *activityService;

@end

NS_ASSUME_NONNULL_END
