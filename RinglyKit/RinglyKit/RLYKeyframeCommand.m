#import "RLYCommand+Internal.h"
#import "RLYKeyframeCommand.h"

@implementation RLYKeyframeCommand

#pragma mark - Initialization
-(instancetype)initWithColorKeyframes:(NSArray<RLYColorKeyframe*>*)colorKeyframes
                   vibrationKeyframes:(NSArray<RLYVibrationKeyframe*>*)vibrationKeyframes
                          repeatCount:(uint8_t)repeatCount
{
    self = [super init];
    
    if (self)
    {
        _colorKeyframes = [NSArray arrayWithArray:colorKeyframes];
        _vibrationKeyframes = [NSArray arrayWithArray:vibrationKeyframes];
        _repeatCount = repeatCount;
    }
    
    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(\n\tLED = %@,\n\tvibration = %@\n)", _colorKeyframes, _vibrationKeyframes];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetKeyframe;
}

-(NSData*)extraData
{
    size_t totalSize = (sizeof(uint8_t) * 5) * _colorKeyframes.count + (sizeof(uint8_t) * 3) * _vibrationKeyframes.count + sizeof(_repeatCount);
    NSMutableData *data = [NSMutableData dataWithCapacity:totalSize];
    
    for (RLYColorKeyframe *keyframe in _colorKeyframes)
    {
        uint8_t bytes[] = {
            keyframe.timestamp,
            keyframe.color.red,
            keyframe.color.green,
            keyframe.color.blue,
            keyframe.interpolateToNext ? 1 : 0
        };
        
        [data appendBytes:bytes length:sizeof(bytes)];
    }
    
    uint8_t separator = 0xff;
    uint8_t repeatSeparator = 0xfe;
    
    [data appendBytes:&separator length:sizeof(separator)];
    
    for (RLYVibrationKeyframe *keyframe in _vibrationKeyframes)
    {
        uint8_t bytes[] = {
            keyframe.timestamp,
            keyframe.vibrationPower,
            keyframe.interpolateToNext ? 29 : 0
        };
        
        [data appendBytes:bytes length:sizeof(bytes)];
    }
    
    [data appendBytes:&repeatSeparator length:sizeof(repeatSeparator)];
    [data appendBytes:&_repeatCount length:sizeof(_repeatCount)];

    
    return data;
}

@end
