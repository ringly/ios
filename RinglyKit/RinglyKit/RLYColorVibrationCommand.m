#import "RLYCommand+Internal.h"
#import "RLYColorVibrationCommand.h"

NSUInteger const RLYColorVibrationCommandMillisecondsPerUnit = 50;

@implementation RLYColorVibrationCommand

#pragma mark - Initialization
-(instancetype)initWithColorBehavior:(RLYColorBehavior*)colorBehavior
                   vibrationBehavior:(RLYVibrationBehavior*)vibrationBehavior
{
    self = [super init];

    if (self)
    {
        _colorBehavior = colorBehavior;
        _vibrationBehavior = vibrationBehavior;
    }

    return self;
}

+(instancetype)commandWithColor:(RLYColor)color
                 secondaryColor:(RLYColor)secondaryColor
                      vibration:(RLYVibration)vibration
{
    return [self commandWithColor:color secondaryColor:secondaryColor vibration:vibration LEDFadeDuration:25];
}

+(instancetype)commandWithColor:(RLYColor)color
                 secondaryColor:(RLYColor)secondaryColor
                      vibration:(RLYVibration)vibration
                LEDFadeDuration:(uint8_t)LEDFadeDuration
{
    uint8_t vibrationCount = RLYVibrationToCount(vibration);

    RLYColorBehavior *colorBehavior = [[RLYColorBehavior alloc] initWithCount:1
                                                                        color:color
                                                               secondaryColor:secondaryColor
                                                                        delay:50 * vibrationCount
                                                                   durationOn:LEDFadeDuration
                                                                  durationOff:LEDFadeDuration];

    RLYVibrationBehavior *vibrationBehavior = [[RLYVibrationBehavior alloc] initWithCount:vibrationCount
                                                                                    power:173
                                                                               durationOn:5
                                                                              durationOff:5];

    return [[self alloc] initWithColorBehavior:colorBehavior vibrationBehavior:vibrationBehavior];
}

+(instancetype)commandWithAzureColorAndVibration:(RLYVibration)vibration
{
    return [self commandWithColor:RLYColorMake(0, 155, 135)
                   secondaryColor:RLYColorNone
                        vibration:vibration];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"color behavior = (%@), vibration behavior = (%@)",
            _colorBehavior, _vibrationBehavior];
}

#pragma mark - Command Data
-(RLYCommandType)type
{
    return RLYCommandTypePresetLEDVibration;
}

-(NSData*)extraData
{
    uint8_t bytes[] = {
        _colorBehavior.color.red,
        _colorBehavior.color.green,
        _colorBehavior.color.blue,
        _colorBehavior.secondaryColor.red,
        _colorBehavior.secondaryColor.green,
        _colorBehavior.secondaryColor.blue,
        _colorBehavior.delay,
        _colorBehavior.durationOn,
        _colorBehavior.durationOff,
        _colorBehavior.count,
        _vibrationBehavior.power,
        _vibrationBehavior.durationOn,
        _vibrationBehavior.durationOff,
        _vibrationBehavior.count
    };
    
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}


@end
