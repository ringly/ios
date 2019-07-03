#import "RLYPeripheral.h"
#import "RLYRecoveryPeripheral.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  The current state of a discovery operation being performed by a `RLYCentral`.
 */
@interface RLYCentralDiscovery : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable.
 */
-(instancetype)init NS_UNAVAILABLE;

#pragma mark - Peripherals

/**
 *  The peripherals that have been discovered while searching.
 *
 *  This object is an array of `RLYPeripheral` objects.
 */
@property (nonatomic, readonly, strong) NSArray<RLYPeripheral*> *peripherals;

/**
 *  The peripherals in recovery (firmware update) mode that have been discovered while searching.
 *
 *  This object is an array of `RLYRecoveryPeripheral` objects.
 */
@property (nonatomic, readonly, strong) NSArray<RLYRecoveryPeripheral*> *recoveryPeripherals;

/**
 *  The date at which discovery was started, if any.
 */
@property (nonatomic, readonly, strong) NSDate *startDate;

@end

NS_ASSUME_NONNULL_END
