#import "RLYDefines.h"
#import "RLYPeripheralCharacteristics.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents the characteristics of the logging service.
 */
RINGLYKIT_FINAL @interface RLYPeripheralLoggingCharacteristics : NSObject <RLYPeripheralCharacteristics>

#pragma mark - Characteristics

/**
 *  The logging flash characteristic.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *flash;

/**
 *  The logging request characteristic.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *request;

@end

NS_ASSUME_NONNULL_END
