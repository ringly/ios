#import "RLYCommand+Internal.h"
#import "RLYClearBondsCommand.h"

@implementation RLYClearBondsCommand

-(RLYCommandType)type
{
    return RLYCommandTypePresetClearBonds;
}

-(NSString*)description
{
    return @"Clear Bonds";
}

@end
