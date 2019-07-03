#import "RLYPeripheralLoggingCharacteristics.h"
#import "RLYUUID.h"

@implementation RLYPeripheralLoggingCharacteristics

+(instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic*>*)characteristics
                                                      error:(NSError * _Nullable __autoreleasing *)error
{
    NSDictionary *dictionary = RLYMapCharacteristicsToUUIDs(characteristics);

    RLYPeripheralLoggingCharacteristics *logging = [[self alloc] init];

    if (logging)
    {
        logging->_flash = dictionary[[RLYUUID loggingServiceFlashLogCharacteristicLong]]
                       ?: dictionary[[RLYUUID loggingServiceFlashLogCharacteristicShort]];

        logging->_request = dictionary[[RLYUUID loggingServiceRequestCharacteristicLong]]
                         ?: dictionary[[RLYUUID loggingServiceRequestCharacteristicShort]];
    }

    return logging;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(Logging characteristics: flash - %@)", _flash];
}

@end
