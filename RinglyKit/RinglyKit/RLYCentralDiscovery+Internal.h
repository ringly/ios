#import "RLYCentralDiscovery.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLYCentralDiscovery ()

#pragma mark - Initialization

/**
 *  Initializes a central discovery value.
 *
 *  @param peripherals         The discovered peripherals.
 *  @param recoveryPeripherals The discovered recovery peripherals.
 *  @param startDate           The date at which discovery began.
 */
-(instancetype)initWithPeripherals:(NSArray<RLYPeripheral*>*)peripherals
               recoveryPeripherals:(NSArray<RLYRecoveryPeripheral*>*)recoveryPeripherals
                         startDate:(NSDate*)startDate;

@end

NS_ASSUME_NONNULL_END
