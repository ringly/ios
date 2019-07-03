#import "RLYDefines.h"
#import "RLYPeripheralCharacteristics.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents the characteristics of the device information service.
 */
RINGLYKIT_FINAL @interface RLYPeripheralDeviceInformationCharacteristics : NSObject <RLYPeripheralCharacteristics>

#pragma mark - Characteristics

/**
 *  The MAC address characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *MACAddress;

/**
 *  The application version characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *application;

/**
 *  The hardware version characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *hardware;

/**
 *  The chip version characteristic. This characteristic is not available on older firmware versions.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *chip;

/**
 *  The manufacturer characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *manufacturer;

/**
 *  The bootloader version characteristic. This characteristic is not available on older firmware versions.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *bootloader;

/**
 *  The softdevice version characteristic. This characteristic is not available on older firmware versions.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *softdevice;

@end

NS_ASSUME_NONNULL_END
