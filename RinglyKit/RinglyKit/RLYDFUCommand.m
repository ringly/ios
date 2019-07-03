#import "RLYCommand+Internal.h"
#import "RLYDFUCommand.h"

@implementation RLYDFUCommand

#pragma mark - Initialization
-(instancetype)initWithTimeout:(RLYDFUCommandTimeout)timeout
{
    self = [super init];
    
    if (self)
    {
        _timeout = timeout;
    }
    
    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"DFU (%@)", RLYDFUCommandTimeoutToString(_timeout)];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetDFU;
}

-(NSData*)extraData
{
    // for byte 4, 0 equals 30sec in DFU mode.  Other options are as follows:  1=5s, 2=10s, 3=15s, 4=20s, 5=25s, 6=35s, 7=40s, etc.
    uint8_t bytes[] = { (uint8_t)_timeout };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end

NSString *RLYDFUCommandTimeoutToString(RLYDFUCommandTimeout DFUCommandTimeout)
{
    switch (DFUCommandTimeout)
    {
        case RLYDFUCommandTimeout5:
            return @"5 second timeout";
        case RLYDFUCommandTimeout10:
            return @"10 second timeout";
        case RLYDFUCommandTimeout15:
            return @"15 second timeout";
        case RLYDFUCommandTimeout20:
            return @"20 second timeout";
        case RLYDFUCommandTimeout25:
            return @"25 second timeout";
        case RLYDFUCommandTimeout30:
            return @"30 second timeout";
        case RLYDFUCommandTimeout35:
            return @"35 second timeout";
        case RLYDFUCommandTimeout40:
            return @"40 second timeout";
    }
}
