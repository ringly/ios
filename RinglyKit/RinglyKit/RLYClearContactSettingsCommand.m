#import "RLYClearContactSettingsCommand.h"
#import "RLYCommand+Internal.h"

@implementation RLYClearContactSettingsCommand

-(RLYCommandType)type
{
    return RLYCommandTypePresetContactSettings;
}

-(NSString*)description
{
    return @"Clear Contact Settings";
}

-(NSData*)extraData
{
    uint8_t byte = 0xff;
    return [NSData dataWithBytes:&byte length:sizeof(byte)];
}

@end
