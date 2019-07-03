#import "RLYVibrationKeyframe.h"

@implementation RLYVibrationKeyframe

-(instancetype)initWithTimestamp:(RLYKeyframeTimestamp)timestamp
                  vibrationPower:(RLYVibrationPower)vibrationPower
               interpolateToNext:(BOOL)interpolateToNext
{
    self = [super init];
    
    if (self)
    {
        _timestamp = timestamp;
        _vibrationPower = vibrationPower;
        _interpolateToNext = interpolateToNext;
    }
    
    return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(%d, %d, %@)",
            (int)_timestamp,
            (int)_vibrationPower,
            _interpolateToNext ? @", interpolate" : @""];
}

@end
