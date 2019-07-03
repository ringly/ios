#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Peripheral Errors

/**
 *  The error domain for errors caused by `RLYPeripheral` instances.
 */
RINGLYKIT_EXTERN NSString *const RLYPeripheralErrorDomain;

/**
 *  Enumerates the possible error codes for errors with domain `RLYPeripheralErrorDomain`.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralErrorCode)
{
    /**
     *  The peripheral disconnected while performing the task that errored.
     */
    RLYPeripheralErrorCodePeripheralDisconnected,
    
    // ringly service
    
    /**
     *  The Ringly service was not found.
     */
    RLYPeripheralErrorCodeRinglyServiceNotFound,
    
    /**
     *  The Ringly command characteristic was not found.
     */
    RLYPeripheralErrorCodeCommandCharacteristicNotFound,
    
    /**
     *  The Ringly message characteristic was not found.
     */
    RLYPeripheralErrorCodeMessageCharacteristicNotFound,
    
    /**
     *  A Ringly ANCS notification characteristic was not found.
     */
    RLYPeripheralErrorCodeANCSNotificationCharacteristicNotFound,
    
    /**
     *  Too many Ringly ANCS notification characteristics were found.
     */
    RLYPeripheralErrorCodeTooManyANCSNotificationCharacteristicsFound,
    
    /**
     *  The Ringly bond characteristic was not found.
     */
    RLYPeripheralErrorCodeBondCharacteristicNotFound,
    
    /**
     *  The Ringly clear bond characteristic was not found.
     */
    RLYPeripheralErrorCodeClearBondCharacteristicNotFound,
    
    /**
     *  The Ringly configuration hash characteristic was not found.
     */
    RLYPeripheralErrorCodeConfigurationHashCharacteristicNotFound,
    
    // device information service
    
    /**
     *  The device information service was not found.
     */
    RLYPeripheralErrorCodeDeviceInformationServiceNotFound,
    
    /**
     *  The device firmware characteristic was not found.
     */
    RLYPeripheralErrorCodeDeviceApplicationCharacteristicNotFound,
    
    /**
     *  The device hardware characteristic was not found.
     */
    RLYPeripheralErrorCodeDeviceHardwareCharacteristicNotFound,
    
    /**
     *  The device hardware characteristic was not found.
     */
    RLYPeripheralErrorCodeDeviceManufacturerCharacteristicNotFound,
    
    // battery service
    
    /**
     *  The battery service was not found.
     */
    RLYPeripheralErrorCodeBatteryServiceNotFound,
    
    /**
     *  The battery state characteristic was not found.
     */
    RLYPeripheralErrorCodeBatteryStateCharacteristicNotFound,
    
    /**
     *  The battery charge characteristic was not found.
     */
    RLYPeripheralErrorCodeBatteryChargeCharacteristicNotFound,

    // activity service

    /**
     *  The activity service was found, but its control point characteristic was not found.
     */
    RLYPeripheralErrorCodeActivityControlPointCharacteristicNotFound,

    /**
     *  The activity service was found, but its tracking data characteristic was not found.
     */
    RLYPeripheralErrorCodeActivityTrackingDataCharacteristicNotFound,

    // logging service

    /**
     *  The battery service was not found.
     */
    RLYPeripheralErrorCodeLoggingServiceNotFound,

    /**
     *  The logging service was found, but its flash characteristic was not found.
     */
    RLYPeripheralErrorCodeLoggingFlashCharacteristicNotFound,

    /**
     *  The logging service was found, but its request characteristic was not found.
     */
    RLYPeripheralErrorCodeLoggingRequestCharacteristicNotFound,

    // services
    
    /**
     *  No Bluetooth services were found.
     */
    RLYPeripheralErrorCodeNoServicesFound,
    
    // errors
    
    /**
     *  The data object was of an incorrect length.
     */
    RLYPeripheralErrorCodeIncorrectLength,

    /**
     *  The client attempted to read activity data, but the peripheral is not subscribed to activity notifications.
     */
    RLYPeripheralErrorCodeNotSubscribedToActivityNotifications
};

NS_ASSUME_NONNULL_END
