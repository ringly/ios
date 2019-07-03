#import "RLYPeripheralANCSNotificationModeInformation.h"
#import "RLYPeripheralActivityTracking.h"
#import "RLYPeripheralBatteryInformation.h"
#import "RLYPeripheralConfigurationHashing.h"
#import "RLYPeripheralConnectionInformation.h"
#import "RLYPeripheralDeviceInformation.h"
#import "RLYPeripheralLogging.h"
#import "RLYPeripheralObservation.h"
#import "RLYPeripheralReading.h"
#import "RLYPeripheralValidation.h"
#import "RLYPeripheralWriting.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Wraps a Core Bluetooth `CBPeripheral` object. `RLYPeripheral` is not allocated and initialized by clients of the
 framework. Instead, clients receive an instance from a `RLYCentral` object.
 
 As with other RinglyKit classes, all `@property` values can be observed with KVO, and subclassing is disallowed.
 Information that cannot be represented at a property is delivered via an observer protocol, `RLYPeripheralObserver`.
 
 `RLYPeripheral` generally does not declare instance messages itself. Instead, it implements a number of protocols, one
 for each component of a peripheral's functionality. These protocols are:
 
 - `RLYPeripheralANCSNotificationModeInformation`
 - `RLYPeripheralBatteryInformation`
 - `RLYPeripheralConfigurationHashing`
 - `RLYPeripheralConnectionInformation`
 - `RLYPeripheralDeviceInformation`
 - `RLYPeripheralLogging`
 - `RLYPeripheralObservation`
 - `RLYPeripheralReading`
 - `RLYPeripheralValidation`
 - `RLYPeripheralWriting`
 
 This allows individual components of a peripheral to be mocked for testing.
 */
RINGLYKIT_FINAL @interface RLYPeripheral : NSObject
    <RLYPeripheralANCSNotificationModeInformation,
     RLYPeripheralActivityTracking,
     RLYPeripheralBatteryInformation,
     RLYPeripheralConfigurationHashing,
     RLYPeripheralConnectionInformation,
     RLYPeripheralDeviceInformation,
     RLYPeripheralLogging,
     RLYPeripheralObservation,
     RLYPeripheralReading,
     RLYPeripheralValidation,
     RLYPeripheralWriting>

#pragma mark - Initialization

/**
 *  `RLYPeripheral` cannot be initialized - instances should be retrieved from a `RLYCentral` instance.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `RLYPeripheral` cannot be initialized - instances should be retrieved from a `RLYCentral` instance.
 */
-(instancetype)init NS_UNAVAILABLE;

#pragma mark - Invalidating Properties

/// Resets the peripheral's device information properties, described in `RLYPeripheralDeviceInformation`.
-(void)invalidateDeviceInformation;

#pragma mark - Service & Characteristic Descriptions

/**
 Returns a readable description for the service with the specified UUID.

 @param UUID The UUID.
 @return If the UUID is a known Ringly service UUID, a description. Otherwise, `nil`.
 */
+(nullable NSString*)descriptionForServiceWithUUID:(CBUUID*)UUID;

/**
 Returns a readable description for the characteristic with the specified UUID.

 @param UUID The UUID.
 @return If the UUID is a known Ringly characteristic UUID, a description. Otherwise, `nil`.
 */
+(nullable NSString*)descriptionForCharacteristicWithUUID:(CBUUID*)UUID;

-(void)addValidationError:(NSError*)error;

@end

NS_ASSUME_NONNULL_END
