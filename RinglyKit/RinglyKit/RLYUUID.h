#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A container for common Ringly UUIDs.
 */
@interface RLYUUID : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable - `RLYUUID` is a container for static UUIDs, and cannot be initialized.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable - `RLYUUID` is a container for static UUIDs, and cannot be initialized.
 */
-(instancetype)init NS_UNAVAILABLE;

#pragma mark - Ringly Service

/**
 *  Returns `+ringlyServiceShort` and `+ringlyServiceLong` in an array.
 */
+(NSArray*)allRinglyServiceUUIDs;

/**
 *  The UUID for the Ringly service, short version.
 */
+(CBUUID*)ringlyServiceShort;

/**
 *  The UUID for the Ringly service, long version.
 */
+(CBUUID*)ringlyServiceLong;

/**
 *  The UUID for the Ringly service's write characteristic, short version.
 */
+(CBUUID*)writeCharacteristicShort;

/**
 *  The UUID for the Ringly service's write characteristic, long version.
 */
+(CBUUID*)writeCharacteristicLong;

/**
 *  The UUID for the Ringly service's tap characteristic, short version.
 */
+(CBUUID*)messageCharacteristicShort;

/**
 *  The UUID for the Ringly service's tap characteristic, long version.
 */
+(CBUUID*)messageCharacteristicLong;

/**
 *  The UUID for the Ringly service's notify characteristic, short version.
 */
+(CBUUID*)ANCSVersion1CharacteristicShort;

/**
 *  The UUID for the Ringly service's notify characteristic, long version.
 */
+(CBUUID*)ANCSVersion1CharacteristicLong;

/**
 *  The UUID for the Ringly service's ANCS information characteristic.
 */
+(CBUUID*)ANCSVersion2Characteristic;

/**
 *  The UUID for the Ringly service's bond characteristic.
 */
+(CBUUID*)bondCharacteristic;

/**
 *  The UUID for the Ringly service's clear bond characteristic.
 */
+(CBUUID*)clearBondCharacteristic;

/**
 *  The UUID for the Ringly service's configuration hash characteristic.
 */
+(CBUUID*)configurationHashCharacteristic;

#pragma mark - Battery Service

/**
 *  The UUID for the battery service.
 */
+(CBUUID*)batteryService;

/**
 *  The UUID for the battery service's battery level characteristic.
 */
+(CBUUID*)batteryLevelCharacteristic;

/**
 *  The UUID for the battery service's charge state characteristic.
 */
+(CBUUID*)chargeStateCharacteristic;

#pragma mark - Device Information Service

/**
 *  The UUID for the device information service.
 */
+(CBUUID*)deviceInformationService;

/**
 *  The UUID for the device information service's MAC address characteristic.
 */
+(CBUUID*)MACAddressCharacteristic;

/**
 *  The UUID for the device information service's firmware version characteristic.
 */
+(CBUUID*)applicationVersionCharacteristic;

/**
 *  The UUID for the device information service's hardware version characteristic.
 */
+(CBUUID*)hardwareVersionCharacteristic;

/**
 *  The UUID for the device information service's chip version characteristic.
 */
+(CBUUID*)chipVersionCharacteristic;

/**
 *  The UUID for the device information service's bootloader version characteristic.
 */
+(CBUUID*)bootloaderVersionCharacteristic;

/**
 *  The UUID for the device information service's softdevice version characteristic.
 */
+(CBUUID*)softdeviceVersionCharacteristic;

/**
 *  The UUID for the device information service's manufacturer characteristic.
 */
+(CBUUID*)manufacturerCharacteristic;

#pragma mark - Activity Service

/**
 *  The UUID for the activity service.
 */
+(CBUUID*)activityService;

/**
 *  The UUID for the activity service's control point characteristic.
 */
+(CBUUID*)activityServiceControlPointCharacteristic;

/**
 *  The UUID for the activity service's tracking data characteristic.
 */
+(CBUUID*)activityServiceTrackingDataCharacteristic;

#pragma mark - Logging Service

/**
 *  The UUID for the logging service, short version.
 */
+(CBUUID*)loggingServiceShort;

/**
 *  The UUID for the logging service, long version.
 */
+(CBUUID*)loggingServiceLong;

/**
 *  The UUID for the logging service's flash log characteristic, short version.
 */
+(CBUUID*)loggingServiceFlashLogCharacteristicShort;

/**
 *  The UUID for the logging service's flash log characteristic, long version.
 */
+(CBUUID*)loggingServiceFlashLogCharacteristicLong;

/**
 *  The UUID for the logging service's request characteristic, short version.
 */
+(CBUUID*)loggingServiceRequestCharacteristicShort;

/**
 *  The UUID for the logging service's request characteristic, long version.
 */
+(CBUUID*)loggingServiceRequestCharacteristicLong;

#pragma mark - Services

/**
 An array of all service UUIDs.
 */
+(NSArray*)allServiceUUIDs;

@end

NS_ASSUME_NONNULL_END
