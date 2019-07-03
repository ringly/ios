#import "RLYDefines.h"
#import "RLYPeripheralCharacteristics.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents the characteristics of the Ringly service.
 */
RINGLYKIT_FINAL @interface RLYPeripheralRinglyCharacteristics : NSObject <RLYPeripheralCharacteristics>

#pragma mark - Characteristics

/**
 *  The characteristic used to write commands.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *command;

/**
 *  The characteristic that short messages are sent on, via notify.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *message;

/**
 *  The characteristic that ANCS notifications are sent on, version 1.
 *
 *  In a valid instance, either this property of `ANCSVersion2` will be non-`nil`.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *ANCSVersion1;

/**
 *  The characteristic that ANCS notifications are sent on, version 2.
 *
 *  In a valid instance, either this property of `ANCSVersion1` will be non-`nil`.
 */
@property (nullable, readonly, nonatomic, strong) CBCharacteristic *ANCSVersion2;

/**
 *  The bond information characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *bond;

/**
 *  The clear bond characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *clearBond;

/**
 *  The configuration hash characteristic.
 */
@property (readonly, nonatomic, strong) CBCharacteristic *configurationHash;

@end

NS_ASSUME_NONNULL_END
