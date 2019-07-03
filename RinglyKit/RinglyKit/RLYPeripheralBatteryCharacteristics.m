#import "RLYErrorFunctions.h"
#import "RLYPeripheralBatteryCharacteristics.h"
#import "RLYUUID.h"

@implementation RLYPeripheralBatteryCharacteristics

+(instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic*>*)characteristics
                                                      error:(NSError * _Nullable __autoreleasing *)error
{
    // find characteristics
    NSDictionary *dictionary = RLYMapCharacteristicsToUUIDs(characteristics);
    
    CBCharacteristic *charge = dictionary[[RLYUUID batteryLevelCharacteristic]];
        
    if (!charge)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeBatteryChargeCharacteristicNotFound);
        return nil;
    }
    
    CBCharacteristic *state = dictionary[[RLYUUID chargeStateCharacteristic]];
    
    if (!state)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeBatteryStateCharacteristicNotFound);
        return nil;
    }
    
    // create object, map characteristics to properties
    RLYPeripheralBatteryCharacteristics *peripheralCharacteristics = [[self alloc] init];
    
    if (peripheralCharacteristics)
    {
        peripheralCharacteristics->_charge = charge;
        peripheralCharacteristics->_state = state;
    }
    
    return peripheralCharacteristics;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(Battery characteristics: charge: %@, state: %@)", _charge, _state];
}

@end
