#import "RLYDefines.h"
#import "RLYPeripheralCharacteristics.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents the characteristics of the battery service.
 */
RINGLYKIT_FINAL @interface RLYPeripheralBatteryCharacteristics : NSObject <RLYPeripheralCharacteristics>

#pragma mark - Characteristics

/**
 *  The battery charge characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *charge;

/**
 *  The battery state characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *state;

@end

NS_ASSUME_NONNULL_END
