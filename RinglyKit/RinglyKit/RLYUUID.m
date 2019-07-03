#import "RLYUUID.h"

@implementation RLYUUID

#pragma mark - Ringly Service
+(NSArray*)allRinglyServiceUUIDs
{
    return @[[self ringlyServiceLong], [self ringlyServiceShort]];
}

+(CBUUID*)ringlyServiceShort
{
    return [CBUUID UUIDWithString:@"FFF0"];
}

+(CBUUID*)ringlyServiceLong
{
    return [CBUUID UUIDWithString:@"ebdf3d60-706f-636f-9077-0002a5d5c51b"];
}

+(CBUUID*)writeCharacteristicShort
{
    return [CBUUID UUIDWithString:@"fff2"];
}

+(CBUUID*)writeCharacteristicLong
{
    return [CBUUID UUIDWithString:@"ebdf00a0-706F-636F-9077-0002a5d5c51b"];
}

+(CBUUID*)messageCharacteristicShort
{
    return [CBUUID UUIDWithString:@"fff3"];
}

+(CBUUID*)messageCharacteristicLong
{
    return [CBUUID UUIDWithString:@"ebdf08a0-706F-636F-9077-0002a5d5c51b"];
}

+(CBUUID*)ANCSVersion1CharacteristicShort
{
    return [CBUUID UUIDWithString:@"fff5"];
}

+(CBUUID*)ANCSVersion1CharacteristicLong
{
    return [CBUUID UUIDWithString:@"ebdfe420-706F-636F-9077-0002a5d5c51b"];
}

+(CBUUID*)ANCSVersion2Characteristic
{
    return [CBUUID UUIDWithString:@"ebdfff00-706f-636f-9077-0002a5d5c51b"];
}

+(CBUUID*)bondCharacteristic
{
    return [CBUUID UUIDWithString:@"ebdff0a0-706f-636f-9077-0002a5d5c51b"];
}

+(CBUUID*)clearBondCharacteristic
{
    return [CBUUID UUIDWithString:@"EBDF000F-706F-636F-9077-0002A5D5C51B"];
}

+(CBUUID*)configurationHashCharacteristic
{
    return [CBUUID UUIDWithString:@"ebdfcccc-706f-636f-9077-0002a5d5c51b"];
}

#pragma mark - Device Information Service
+(CBUUID*)deviceInformationService
{
    return [CBUUID UUIDWithString:@"180A"];
}

+(CBUUID*)MACAddressCharacteristic
{
    return [CBUUID UUIDWithString:@"2A25"];
}

+(CBUUID*)applicationVersionCharacteristic
{
    return [CBUUID UUIDWithString:@"2A26"];
}

+(CBUUID*)hardwareVersionCharacteristic
{
    return [CBUUID UUIDWithString:@"2A27"];
}

+(CBUUID*)bootloaderVersionCharacteristic
{
    return [CBUUID UUIDWithString:@"2AAB"];
}

+(CBUUID*)softdeviceVersionCharacteristic
{
    return [CBUUID UUIDWithString:@"2AAD"];
}

+(CBUUID*)chipVersionCharacteristic
{
    return [CBUUID UUIDWithString:@"2AAC"];
}

+(CBUUID*)manufacturerCharacteristic
{
    return [CBUUID UUIDWithString:@"2A29"];
}

#pragma mark - Battery Service
+(CBUUID*)batteryService
{
    return [CBUUID UUIDWithString:@"180F"];
}

+(CBUUID*)batteryLevelCharacteristic
{
    return [CBUUID UUIDWithString:@"2A19"];
}

+(CBUUID*)chargeStateCharacteristic
{
    return [CBUUID UUIDWithString:@"2A1B"];
}

#pragma mark - Activity Service
+(CBUUID*)activityService
{
    return [CBUUID UUIDWithString:@"7bb5e345-3359-48fd-b6f6-4fc86056ac70"];
}

+(CBUUID*)activityServiceControlPointCharacteristic
{
    return [CBUUID UUIDWithString:@"7bb5cafe-3359-48fd-b6f6-4fc86056ac70"];
}

+(CBUUID*)activityServiceTrackingDataCharacteristic
{
    return [CBUUID UUIDWithString:@"7bb5feed-3359-48fd-b6f6-4fc86056ac70"];
}

#pragma mark - Logging Service
+(CBUUID*)loggingServiceShort
{
    return [CBUUID UUIDWithString:@"FFE0"];
}

+(CBUUID*)loggingServiceLong
{
    return [CBUUID UUIDWithString:@"d2b1ad60-604f-11e4-8460-0002a5d5c51b"];
}

+(CBUUID*)loggingServiceFlashLogCharacteristicShort
{
    return [CBUUID UUIDWithString:@"FFE2"];
}

+(CBUUID*)loggingServiceFlashLogCharacteristicLong
{
    return [CBUUID UUIDWithString:@"d2b14a20-604f-11e4-8460-0002a5d5c51b"];
}

+(CBUUID*)loggingServiceRequestCharacteristicShort
{
    return [CBUUID UUIDWithString:@"FFF2"];
}

+(CBUUID*)loggingServiceRequestCharacteristicLong
{
    return [CBUUID UUIDWithString:@"d2b1af60-604f-11e4-8460-0002a5d5c51b"];
}

#pragma mark - Services
+(NSArray*)allServiceUUIDs
{
    return @[[self ringlyServiceLong],
             [self ringlyServiceShort],
             [self deviceInformationService],
             [self batteryService],
             [self activityService],
             [self loggingServiceLong],
             [self loggingServiceShort]];
}

@end
