#import "NSDictionary+Ringly.h"

@implementation NSDictionary (Ringly)

-(instancetype)rly_dictionaryByRemovingNSNull
{
    NSMutableDictionary *copy = [self mutableCopy];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj == [NSNull null])
        {
            [copy removeObjectForKey:key];
        }
        
        if ([obj isKindOfClass:[NSDictionary class]])
        {
            copy[key] = [obj rly_dictionaryByRemovingNSNull];
        }
    }];
    
    return copy;
}

@end
