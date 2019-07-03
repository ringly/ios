#import "RLYClearApplicationSettingsCommand.h"
#import "RLYCommand+Internal.h"

@implementation RLYClearApplicationSettingsCommand

-(RLYCommandType)type
{
    return RLYCommandTypePresetApplicationSettings;
}

-(NSData*)extraData
{
    uint8_t byte = 0xff;
    return [NSData dataWithBytes:&byte length:sizeof(byte)];
}

-(NSString*)description
{
    return @"Clear Application Settings";
}

@end
