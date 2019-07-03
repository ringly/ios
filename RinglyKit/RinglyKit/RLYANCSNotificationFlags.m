#import "RLYANCSNotificationFlags.h"

@implementation RLYANCSNotificationFlagsValue

-(instancetype)initWithFlags:(RLYANCSNotificationFlags)flags
{
    self = [super init];
    
    if (self)
    {
        _flags = flags;
    }
    
    return self;
}

-(NSString*)description
{
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:5];
    
    if ((_flags & RLYANCSNotificationFlagsImportant) != 0)
    {
        [strings addObject:@"Important"];
    }
    
    if ((_flags & RLYANCSNotificationFlagsSilent) != 0)
    {
        [strings addObject:@"Silent"];
    }
    
    if ((_flags & RLYANCSNotificationFlagsPreExisting) != 0)
    {
        [strings addObject:@"Pre-Existing"];
    }
    
    if ((_flags & RLYANCSNotificationFlagsNegativeAction) != 0)
    {
        [strings addObject:@"Negative Action"];
    }
    
    if ((_flags & RLYANCSNotificationFlagsPositiveAction) != 0)
    {
        [strings addObject:@"Positive Action"];
    }
    
    if (strings.count == 0)
    {
        return @"<none>";
    }
    else
    {
        return [NSString stringWithFormat:@"(%@)", [strings componentsJoinedByString:@", "]];
    }
}

@end
