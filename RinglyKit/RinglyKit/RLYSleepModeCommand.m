#import "RLYCommand+Internal.h"
#import "RLYSleepModeCommand.h"

uint8_t const RLYSleepModeCommandDefaultSleepTime = 15;
uint8_t const RLYSleepModeCommandDisabledSleepTime = 0;

@implementation RLYSleepModeCommand

#pragma mark - Initialization
-(instancetype)initWithSleepTime:(uint8_t)sleepTime
{
    self = [super init];
    
    if (self)
    {
        _sleepTime = sleepTime;
    }
    
    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"Sleep Time %d", (int)_sleepTime];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetSleepMode;
}

-(NSData*)extraData
{
    uint8_t bytes[] = { _sleepTime };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
