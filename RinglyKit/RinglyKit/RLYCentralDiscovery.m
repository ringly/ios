#import "RLYCentralDiscovery+Internal.h"

@implementation RLYCentralDiscovery

#pragma mark - Initialization
-(instancetype)initWithPeripherals:(NSArray<RLYPeripheral*>*)peripherals
               recoveryPeripherals:(NSArray<RLYRecoveryPeripheral*>*)recoveryPeripherals
                         startDate:(NSDate*)startDate
{
    self = [super init];

    if (self)
    {
        _peripherals = peripherals;
        _recoveryPeripherals = recoveryPeripherals;
        _startDate = startDate;
    }

    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(peripherals = %@, recovery peripherals = %@, start date = %@)",
            _peripherals, _recoveryPeripherals, _startDate];
}

@end
