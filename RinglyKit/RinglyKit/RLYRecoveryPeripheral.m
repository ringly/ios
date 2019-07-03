#import "RLYFunctions.h"
#import "RLYRecoveryPeripheral+Internal.h"

@implementation RLYRecoveryPeripheral

#pragma mark - Initialization
-(instancetype)initWithPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData
{
    self = [super init];

    if (self)
    {
        _peripheral = peripheral;
        _advertisementData = advertisementData;
    }

    return self;
}

#pragma mark - Hardware Version
-(RLYKnownHardwareVersionValue*)hardwareVersion
{
    NSArray *serviceUUIDs = _advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] ?: @[];

    CBUUID *solicited = RLYFirstMatching(serviceUUIDs, ^BOOL(CBUUID *UUID) {
        return RLYUUIDIsRecoveryModeService(UUID);
    });

    if (solicited)
    {
        if ([[RLYRecoveryPeripheral version1SolicitedServiceUUID] isEqual:solicited])
        {
            return [[RLYKnownHardwareVersionValue alloc] initWithValue:RLYKnownHardwareVersion1];
        }
        else if ([[RLYRecoveryPeripheral version2SolicitedServiceUUID] isEqual:solicited])
        {
            return [[RLYKnownHardwareVersionValue alloc] initWithValue:RLYKnownHardwareVersion2];
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

#pragma mark - Solicited Service UUIDs
+(CBUUID*)version1SolicitedServiceUUID
{
    return [CBUUID UUIDWithString:RLYRecoveryPeripheralVersion1ServiceUUIDString];
}

+(CBUUID*)version2SolicitedServiceUUID
{
    return [CBUUID UUIDWithString:RLYRecoveryPeripheralVersion2ServiceUUIDString];
}

@end

BOOL RLYAdvertismentDataIsInRecoveryMode(NSDictionary *advertisementData)
{
    return RLYAny(advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey], ^BOOL(CBUUID *UUID) {
        return RLYUUIDIsRecoveryModeService(UUID);
    });
}

BOOL RLYUUIDIsRecoveryModeService(CBUUID *UUID)
{
    return [UUID isEqual:[RLYRecoveryPeripheral version1SolicitedServiceUUID]]
        || [UUID isEqual:[RLYRecoveryPeripheral version2SolicitedServiceUUID]];
}

NSString *const RLYRecoveryPeripheralVersion1ServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
NSString *const RLYRecoveryPeripheralVersion2ServiceUUIDString = @"a01f1540-70db-4ce5-952b-873759f85c44";
