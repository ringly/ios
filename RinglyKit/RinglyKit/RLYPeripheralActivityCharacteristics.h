#import "RLYDefines.h"
#import "RLYPeripheralCharacteristics.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents the characteristics of the activity service.
 */
RINGLYKIT_FINAL @interface RLYPeripheralActivityCharacteristics : NSObject <RLYPeripheralCharacteristics>

#pragma mark - Characteristics

/**
 *  The control point characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *controlPoint;

/**
 *  The tracking data characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *trackingData;

@end

NS_ASSUME_NONNULL_END
