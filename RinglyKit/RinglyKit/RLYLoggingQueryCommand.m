#import "RLYCommand+Internal.h"
#import "RLYLoggingQueryCommand.h"

@implementation RLYLoggingQueryCommand

-(instancetype)initWithQuery:(RLYLoggingQuery)query
{
    self = [super init];
    
    if (self)
    {
        _query = query;
    }
    
    return self;
}

-(RLYCommandType)type
{
    return RLYCommandTypePresetLoggingQuery;
}

-(NSData*)extraData
{
    uint8_t bytes[] = { _query };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
