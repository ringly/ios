#import "RLYColorKeyframe.h"

@implementation RLYColorKeyframe

-(instancetype)initWithTimestamp:(RLYKeyframeTimestamp)timestamp
                           color:(RLYColor)color
               interpolateToNext:(BOOL)interpolateToNext
{
    self = [super init];
    
    if (self)
    {
        _timestamp = timestamp;
        _color = color;
        _interpolateToNext = interpolateToNext;
    }
    
    return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(%d, %@%@)",
            (int)_timestamp,
            RLYColorToString(_color),
            _interpolateToNext ? @", interpolate" : @""];
}

@end
