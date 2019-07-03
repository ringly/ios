#import "RLYCommand+Internal.h"
#import "RLYDeepSleepCommand.h"

@implementation RLYDeepSleepCommand

-(RLYCommandType)type
{
    return RLYCommandTypePresetDeepSleep;
}

-(NSString*)description
{
    return @"Deep Sleep";
}

@end
