#import "RLYCommand+Internal.h"
#import "RLYDisconnectVibrationCommand.h"

NSUInteger const RLYDisconnectVibrationCommandMillisecondsPerUnit = 10;

uint8_t const RLYDisconnectVibrationCommandDefaultVibrationCount = 7;
uint8_t const RLYDisconnectVibrationCommandDefaultVibrationDurationOn = 13;
uint8_t const RLYDisconnectVibrationCommandDefaultVibrationDurationOff = 13;
RLYVibrationPower const RLYDisconnectVibrationCommandDefaultVibrationPower = 233;
uint8_t const RLYDisconnectVibrationCommandDefaultWaitTime = 9;
uint8_t const RLYDisconnectVibrationCommandDisabledWaitTime = 0;
uint8_t const RLYDisconnectVibrationCommandDefaultBackoffTime = 10;

@implementation RLYDisconnectVibrationCommand

#pragma mark - Initialization
-(id)initWithVibrationBehavior:(RLYVibrationBehavior *)vibrationBehavior
                      waitTime:(uint8_t)waitTime
                   backoffTime:(uint8_t)backoffTime
{
    self = [super init];
    
    if (self)
    {
        _vibrationBehavior = vibrationBehavior;
        _waitTime = waitTime;
        _backoffTime = backoffTime;
    }
    
    return self;
}

-(instancetype)initWithDefaultsForEnabled:(BOOL)enabled
{
    RLYVibrationBehavior *vibrationBehavior =
        [[RLYVibrationBehavior alloc] initWithCount:RLYDisconnectVibrationCommandDefaultVibrationCount
                                              power:RLYDisconnectVibrationCommandDefaultVibrationPower
                                         durationOn:RLYDisconnectVibrationCommandDefaultVibrationDurationOn
                                        durationOff:RLYDisconnectVibrationCommandDefaultVibrationDurationOff];

    uint8_t waitTime = enabled
        ? RLYDisconnectVibrationCommandDefaultWaitTime
        : RLYDisconnectVibrationCommandDisabledWaitTime;

    return self = [self initWithVibrationBehavior:vibrationBehavior
                                         waitTime:waitTime
                                      backoffTime:RLYDisconnectVibrationCommandDefaultBackoffTime];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:
            @"Disconnect Vibration (vibration = (%@), wait time = %d, backoff time = %d)",
            _vibrationBehavior, _waitTime, _backoffTime];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetDisconnectVibration;
}

-(NSData*)extraData
{
    uint8_t bytes[] = {
        _waitTime,
        _vibrationBehavior.count,
        _vibrationBehavior.durationOn,
        _vibrationBehavior.durationOff,
        _vibrationBehavior.power,
        _backoffTime
    };
    
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
