#import "RLYColorBehavior.h"

@implementation RLYColorBehavior

#pragma mark - Initialization
-(instancetype)initWithCount:(uint8_t)count
                       color:(RLYColor)color
              secondaryColor:(RLYColor)secondaryColor
                       delay:(uint8_t)delay
                  durationOn:(uint8_t)durationOn
                 durationOff:(uint8_t)durationOff
{
    self = [super init];

    if (self)
    {
        _count = count;
        _color = color;
        _secondaryColor = secondaryColor;
        _delay = delay;
        _durationOn = durationOn;
        _durationOff = durationOff;
    }

    return self;
}

+(instancetype)empty
{
    return [[self alloc] initWithCount:0
                                 color:RLYColorNone
                        secondaryColor:RLYColorNone
                                 delay:0
                            durationOn:0
                           durationOff:0];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"count = %d, color = %@, secondary color = %@, delay = %d, on = %d, off = %d",
            (int)_count,
            RLYColorToString(_color),
            RLYColorToString(_secondaryColor),
            (int)_delay,
            (int)_durationOn,
            (int)_durationOff];
}

@end
