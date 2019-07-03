#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Contains messages instructing the peripheral to read information. Sending these messages can cause updates to
 *  properties listed in the protocols:
 *  
 *  - `RLYPeripheralBatteryInformation`
 *  - `RLYPeripheralConnectionInformation`
 *  - `RLYPeripheralDeviceInformation`
 */
@protocol RLYPeripheralReading <NSObject>

#pragma mark - Bond

/**
 *  Whether or not the `-readBondCharacteristic:` message is currently supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport readBondCharacteristicSupport;

/**
 *  Reads the bond characteristic, if available. This is automatically performed upon connection.
 *
 *  @param error An error pointer, which will be set if the characteristic could not be read.
 *
 *  @return `YES` if the characteristic could be read, otherwise `NO`.
 */
-(BOOL)readBondCharacteristic:(NSError**)error;

#pragma mark - Battery

/**
 *  If possible, reads the battery characteristics of the peripheral.
 *
 *  @param error An error pointer, which will be set if the characteristics could not be read.
 *
 *  @return `YES` if all characteristics were present and could be read, otherwise `NO`.
 */
-(BOOL)readBatteryCharacteristics:(NSError**)error;

#pragma mark - Device Information

/**
 *  If possible, reads the device information characteristics of the peripheral.
 *
 *  Some of these characteristics are not present on older application firmware versions. These are not considered
 *  mandatory, so the absense of one of these characteristics will not result in a failure.
 *
 *  @param error An error pointer, which will be set if the characteristics could not be read.
 *
 *  @return `YES` if the required characteristics were present and could be read, otherwise `NO`.
 */
-(BOOL)readDeviceInformationCharacteristics:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
