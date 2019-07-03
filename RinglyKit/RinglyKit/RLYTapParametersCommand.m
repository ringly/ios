#import "RLYCommand+Internal.h"
#import "RLYTapParametersCommand.h"

@implementation RLYTapParametersCommand

#pragma mark - Initialization
-(instancetype)initWithThreshold:(uint8_t)threshold
                       timeLimit:(uint8_t)timeLimit
                         latency:(uint8_t)latency
                          window:(uint8_t)window
                          field5:(uint8_t)field5
                          field6:(uint8_t)field6
                          field7:(uint8_t)field7
                          field8:(uint8_t)field8
                          field9:(uint8_t)field9
                         field10:(uint8_t)field10
{
    self = [super init];

    if (self)
    {
        _threshold = threshold;
        _timeLimit = timeLimit;
        _latency = latency;
        _window = window;
        _field5 = field5;
        _field6 = field6;
        _field7 = field7;
        _field8 = field8;
        _field9 = field9;
        _field10 = field10;
    }

    return self;
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetTapParameters;
}

-(NSData*)extraData
{
    uint8_t bytes[] = {
        _threshold,
        _timeLimit,
        _latency,
        _window,
        _field5,
        _field6,
        _field7,
        _field8,
        _field9,
        _field10
    };
    
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
