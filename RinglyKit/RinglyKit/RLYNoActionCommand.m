#import "RLYCommand+Internal.h"
#import "RLYNoActionCommand.h"

@implementation RLYNoActionCommand

-(NSString*)description
{
    return @"No Action";
}

-(RLYCommandType)type
{
    return RLYCommandTypePresetLEDVibration;
}

@end
