#import <CoreBluetooth/CoreBluetooth.h>
#import "RLYKnownHardwareVersion.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A discovered peripheral in recovery (firmware update) mode.
 */
RINGLYKIT_FINAL @interface RLYRecoveryPeripheral : NSObject

#pragma mark - Initialization

/**
 *  `RLYRecoveryPeripheral` cannot be initialized - instances should be retrieved from a `RLYCentral` instance.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `RLYRecoveryPeripheral` cannot be initialized - instances should be retrieved from a `RLYCentral` instance.
 */
-(instancetype)init NS_UNAVAILABLE;

#pragma mark - Properties

/**
 *  The Core Bluetooth peripheral.
 */
@property (nonatomic, readonly, strong) CBPeripheral *peripheral;

/**
 *  The advertisement data for the discovered peripheral.
 */
@property (nonatomic, readonly, strong) NSDictionary *advertisementData;

#pragma mark - Hardware Version

/**
 *  The known hardware version of the recovery peripheral. If `nil`, the hardware version is unknown.
 */
@property (nullable, nonatomic, readonly) RLYKnownHardwareVersionValue *hardwareVersion;

#pragma mark - Solicited Service UUIDs

/**
 *  The recovery UUID for version 1 peripherals.
 */
+(CBUUID*)version1SolicitedServiceUUID;

/**
 *  The recovery UUID for version 2 peripherals.
 */
+(CBUUID*)version2SolicitedServiceUUID;

@end

NS_ASSUME_NONNULL_END
