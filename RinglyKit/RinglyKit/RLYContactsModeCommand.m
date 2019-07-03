#import "RLYCommand+Internal.h"
#import "RLYContactsModeCommand.h"

@implementation RLYContactsModeCommand

#pragma mark - Initialization
-(instancetype)initWithMode:(RLYContactsMode)mode
{
    self = [super init];
    
    if (self)
    {
        _mode = mode;
    }
    
    return self;
}

#pragma mark - Command
-(RLYCommandType)type
{
    return RLYCommandTypePresetContactsMode;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"Contacts Mode %d", (int)_mode];
}

#pragma mark - Data
-(NSData*)extraData
{
    return [NSData dataWithBytes:&_mode length:sizeof(_mode)];
}

@end
