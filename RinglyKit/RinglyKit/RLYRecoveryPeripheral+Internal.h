#import "RLYRecoveryPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLYRecoveryPeripheral ()

#pragma mark - Initialization

/**
 *  Initializes a recovery peripheral.
 *
 *  @param peripheral        The peripheral in recovery mode.
 *  @param advertisementData The advertisement data for the peripheral.
 */
-(instancetype)initWithPeripheral:(CBPeripheral*)peripheral
                advertisementData:(NSDictionary*)advertisementData NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - UUID Utilities

/// The solicited recovery UUID for Park peripherals.
RINGLYKIT_EXTERN NSString *const RLYRecoveryPeripheralVersion1ServiceUUIDString;

/// The solicited recovery UUID for Madison peripherals.
RINGLYKIT_EXTERN NSString *const RLYRecoveryPeripheralVersion2ServiceUUIDString;

/**
 *  Returns `YES` if the advertisement data passed indicates a peripheral in recovery mode.
 *
 *  @param advertisementData The advertisement data.
 */
RINGLYKIT_EXTERN BOOL RLYAdvertismentDataIsInRecoveryMode(NSDictionary *advertisementData);

/**
 *  Returns `YES` if the UUID passed indicates a peripheral in recovery mode.
 *
 *  @param UUID The UUID.
 */
RINGLYKIT_EXTERN BOOL RLYUUIDIsRecoveryModeService(CBUUID *UUID);

NS_ASSUME_NONNULL_END
