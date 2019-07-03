#import "RLYCommand+Internal.h"
#import "RLYFirmwareResetCommand.h"

@implementation RLYFirmwareResetCommand

-(RLYCommandType)type
{
    return RLYCommandTypePresetFirmwareReset;
}

-(NSString*)description
{
    return @"Firmware Reset";
}

@end
