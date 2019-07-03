#import "RLYANCSTimeoutAlertCommand.h"
#import "RLYCommand+Internal.h"

@implementation RLYANCSTimeoutAlertCommand

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
    return [NSString stringWithFormat:@"ANCS Timeout Alert %@", _enabled ? @"Enabled" : @"Disabled"];
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetANCSTimeoutAlert;
}

-(NSData*)extraData
{
    uint8_t byte = _enabled ? 1 : 0xff;
    return [NSData dataWithBytes:&byte length:sizeof(byte)];
}

@end
