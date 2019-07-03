#import "RLYVibrationBehavior.h"

@implementation RLYVibrationBehavior

#pragma mark - Initialization
-(instancetype)initWithCount:(uint8_t)count
                       power:(uint8_t)power
                  durationOn:(uint8_t)durationOn
                 durationOff:(uint8_t)durationOff
{
    self = [super init];

    if (self)
    {
        _count = count;
        _power = power;
        _durationOn = durationOn;
        _durationOff = durationOff;
    }

    return self;
}

+(instancetype)empty
{
    return [[self alloc] initWithCount:0 power:0 durationOn:0 durationOff:0];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"count = %d, power = %d, on = %d, off = %d",
            (int)_count, (int)_power, (int)_durationOn, (int)_durationOff];
}

@end
