#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  An internal base class for objects containing a number of Core Bluetooth characteristics.
 */
@protocol RLYPeripheralCharacteristics <NSObject>

#pragma mark - Creation

/**
 *  Converts an array of Core Bluetooth characteristics into a characteristics object, if possible.
 *
 *  @param characteristics The array of Core Bluetooth characteristics.
 *  @param error           An error pointer, which will be set if the conversion fails.
 *
 *  @return A characteristics object if conversion is successful, otherwise `nil`.
 */
+(nullable instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic*>*)characteristics
                                                               error:(NSError**)error;

@end

#pragma mark -

static inline NSDictionary *RLYMapCharacteristicsToUUIDs(NSArray *characteristics)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:characteristics.count];
    
    for (CBCharacteristic *characteristic in characteristics)
    {
        dictionary[characteristic.UUID] = characteristic;
    }
    
    return dictionary;
}

NS_ASSUME_NONNULL_END
