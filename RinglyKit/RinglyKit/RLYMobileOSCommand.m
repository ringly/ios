#import "RLYCommand+Internal.h"
#import "RLYMobileOSCommand.h"

@implementation RLYMobileOSCommand

#pragma mark - Initialization
-(instancetype)initWithType:(RLYMobileOSType)mobileOSType
{
    return self = [self initWithType:mobileOSType factoryMode:NO];
}

-(instancetype)initWithType:(RLYMobileOSType)mobileOSType factoryMode:(BOOL)factoryMode
{
    self = [super init];
    
    if (self)
    {
        _mobileOSType = mobileOSType;
        _factoryMode = factoryMode;
    }
    
    return self;
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetMobileOS;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"OS %d, factory mode %d", (int)_mobileOSType, _factoryMode];
}

-(NSData*)extraData
{
    uint8_t bytes[] = { _mobileOSType, _factoryMode ? 1 : 0 };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
