#import "RLYErrorFunctions.h"
#import "RLYPeripheralRinglyCharacteristics.h"
#import "RLYUUID.h"

@implementation RLYPeripheralRinglyCharacteristics

+(instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic*>*)characteristics
                                                      error:(NSError * _Nullable __autoreleasing *)error
{
    // find characteristics
    NSDictionary *dictionary = RLYMapCharacteristicsToUUIDs(characteristics);
    
    // either the ANCS v1 or ANCS v2 characteristic is required
    CBCharacteristic *ANCSVersion1 = dictionary[[RLYUUID ANCSVersion1CharacteristicShort]]
                                  ?: dictionary[[RLYUUID ANCSVersion1CharacteristicLong]];
    
    CBCharacteristic *ANCSVersion2 = dictionary[[RLYUUID ANCSVersion2Characteristic]];
    
    if (!ANCSVersion1 && !ANCSVersion2)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeANCSNotificationCharacteristicNotFound);
        return nil;
    }
    
    if (ANCSVersion1 && ANCSVersion2)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeTooManyANCSNotificationCharacteristicsFound);
        return nil;
    }
    
    // command and message characteristics are required
    CBCharacteristic *commandCharacteristic = dictionary[[RLYUUID writeCharacteristicShort]]
                                          ?: dictionary[[RLYUUID writeCharacteristicLong]];
        
    if (!commandCharacteristic)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeCommandCharacteristicNotFound);
        return nil;
    }
    
    CBCharacteristic *messageCharacteristic = dictionary[[RLYUUID messageCharacteristicShort]]
                                           ?: dictionary[[RLYUUID messageCharacteristicLong]];
    
    if (!messageCharacteristic)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeMessageCharacteristicNotFound);
        return nil;
    }
    
    // the configuration hash characteristic is required alongside ANCS v2
    CBCharacteristic *configurationHash = dictionary[[RLYUUID configurationHashCharacteristic]];
    
    if (ANCSVersion2 && !configurationHash)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeConfigurationHashCharacteristicNotFound);
        return nil;
    }
    
    // the bond characteristic is required alongside ANCS v2
    CBCharacteristic *bondCharacteristic = dictionary[[RLYUUID bondCharacteristic]];
    
    if (ANCSVersion2 && !bondCharacteristic)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeBondCharacteristicNotFound);
        return nil;
    }
    
    // the clear bond characteristic is required alongside ANCS v2
    CBCharacteristic *clearBondCharacteristic = dictionary[[RLYUUID clearBondCharacteristic]];
    
    if (ANCSVersion2 && !clearBondCharacteristic)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeClearBondCharacteristicNotFound);
        return nil;
    }
    
    // create object, map characteristics to properties
    RLYPeripheralRinglyCharacteristics *peripheralCharacteristics = [[self alloc] init];
    
    if (peripheralCharacteristics)
    {
        peripheralCharacteristics->_command = commandCharacteristic;
        peripheralCharacteristics->_message = messageCharacteristic;
        peripheralCharacteristics->_ANCSVersion1 = ANCSVersion1;
        peripheralCharacteristics->_ANCSVersion2 = ANCSVersion2;
        peripheralCharacteristics->_bond = bondCharacteristic;
        peripheralCharacteristics->_clearBond = clearBondCharacteristic;
        peripheralCharacteristics->_configurationHash = configurationHash;
    }
    
    return peripheralCharacteristics;
}

-(NSString*)description
{
    return [NSString stringWithFormat:
            @"(Ringly characteristics: command: %@, message: %@, ANCSv1: %@, ANCSv2: %@, bond: %@, clear bond: %@, configuration hash: %@)",
            _command, _message, _ANCSVersion1, _ANCSVersion2, _bond, _clearBond, _configurationHash];
}

@end
