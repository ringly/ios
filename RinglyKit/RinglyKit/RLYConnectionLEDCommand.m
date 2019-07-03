#import "RLYCommand+Internal.h"
#import "RLYConnectionLEDCommand.h"

@implementation RLYConnectionLEDCommand

#pragma mark - Initialization
-(instancetype)initWithEnabled:(BOOL)enabled
{
    self = [super init];
    
    if (self)
    {
        _enabled = enabled;
    }
    
    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"Connection LED %d", _enabled];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetConnectionLED;
}

-(NSData *)extraData
{
    uint8_t bytes[] = { _enabled ? 1 : 2 };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
