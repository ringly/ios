#import "RLYKnownHardwareVersion.h"
#import "RLYPeripheralEnumerations.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Contains properties describing the current state of the peripheral's device information.
 */
@protocol RLYPeripheralDeviceInformation <NSObject>

#pragma mark - Identity

/**
 *  The peripheral's identifier.
 */
@property (nonatomic, readonly, strong) NSUUID *identifier;

/**
 *  The peripheral's name.
 */
@property (nullable, nonatomic, readonly, strong) NSString *name;

/**
 *  The short name of the peripheral (i.e. `DAYD`, `STAR`).
 */
@property (nullable, nonatomic, readonly) NSString *shortName;

/**
 *  The last four character's of the peripheral's MAC address. These are parsed from the `name` property, so they are
 *  dependant on that property being non-`nil`.
 */
@property (nullable, nonatomic, readonly) NSString *lastFourMAC;

/**
 *  Whether or not the `MACAddress` feature is supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport MACAddressSupport;

/**
 *  The peripheral's MAC address.
 *
 *  This feature is only available on application firmware versions `1.4` and above. On
 *  older firmware versions, the value will always be `nil`.
 *
 *  @see MACAddressSupport
 */
@property (nullable, nonatomic, readonly) NSString *MACAddress;

#pragma mark - Hardware

/**
 *  The hardware version of the peripheral.
 */
@property (nullable, nonatomic, readonly, strong) NSString *hardwareVersion;

/**
 *  Whether or not the `chipVersion` feature is supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport chipVersionSupport;

/**
 *  The chip version of the peripheral.
 *
 *  This feature is only available on application firmware versions `1.4` and above. On
 *  older firmware versions, the value will always be `nil`.
 *
 *  @see chipVersionSupport
 */
@property (nullable, nonatomic, readonly, strong) NSString *chipVersion;

#pragma mark - Firmware

/**
 *  The application firmware version of the peripheral.
 */
@property (nullable, nonatomic, readonly, strong) NSString *applicationVersion;

/**
 *  Whether or not the `bootloaderVersion` feature is supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport bootloaderVersionSupport;

/**
 *  The peripheral's bootloader version.
 *
 *  This feature is only available on application firmware versions `1.4` and above. On
 *  older firmware versions, the value will always be `nil`.
 *
 *  @see bootloaderVersionSupport
 */
@property (nullable, nonatomic, readonly, strong) NSString *bootloaderVersion;

/**
 *  Whether or not the `softdeviceVersion` feature is supported.
 */
@property (nonatomic, readonly) RLYPeripheralFeatureSupport softdeviceVersionSupport;

/**
 *  The softdevice version of the peripheral.
 *
 *  This feature is only available on application firmware versions `1.4` and above. On
 *  older firmware versions, the value will always be `nil`.
 *
 *  @see softdeviceVersionSupport
 */
@property (nullable, nonatomic, readonly, strong) NSString *softdeviceVersion;

#pragma mark - Known Versions

/// The known hardware version, if any, for the peripheral.
@property (nullable, nonatomic, readonly) RLYKnownHardwareVersionValue *knownHardwareVersion;

#pragma mark - Appearance

/**
 *  The style of the peripheral.
 */
@property (nonatomic, readonly) RLYPeripheralStyle style;

/**
 *  The type of the peripheral.
 */
@property (nonatomic, readonly) RLYPeripheralType type;

/**
 *  The style of the peripheral's band.
 */
@property (nonatomic, readonly) RLYPeripheralBand band;

/**
 *  The stone style of the peripheral.
 */
@property (nonatomic, readonly) RLYPeripheralStone stone;

@end

NS_ASSUME_NONNULL_END
