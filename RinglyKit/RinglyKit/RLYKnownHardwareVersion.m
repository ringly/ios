#import "RLYKnownHardwareVersion.h"
#import "RLYRecoveryPeripheral.h"

@implementation RLYKnownHardwareVersionValue

-(instancetype)initWithValue:(RLYKnownHardwareVersion)value
{
    self = [super init];

    if (self)
    {
        _value = value;
    }

    return self;
}

@end

NSString *RLYKnownHardwareVersionDefaultVersionString(RLYKnownHardwareVersion version)
{
    switch (version)
    {
        case RLYKnownHardwareVersion1:
            return @"V00";
        case RLYKnownHardwareVersion2:
            return @"V000";
    }
}

CBUUID *RLYKnownHardwareVersionRecoverySolicitedServiceUUID(RLYKnownHardwareVersion version)
{
    switch (version)
    {
        case RLYKnownHardwareVersion1:
            return [RLYRecoveryPeripheral version1SolicitedServiceUUID];
        case RLYKnownHardwareVersion2:
            return [RLYRecoveryPeripheral version2SolicitedServiceUUID];
    }
}
