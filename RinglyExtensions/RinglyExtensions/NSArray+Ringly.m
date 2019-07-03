#import "NSArray+Ringly.h"

@implementation NSArray (Ringly)

#pragma mark - Functional
+(NSArray*)rly_mapToCount:(NSUInteger)count withBlock:(id(^)(NSUInteger index))block
{
    if (index > 0)
    {
        __autoreleasing id* mapped = (__autoreleasing id*)calloc(count, sizeof(id));
        
        for (NSUInteger i = 0; i < count; i++)
        {
            mapped[i] = block(i);
        }
        
        NSArray* array = [NSArray arrayWithObjects:mapped count:count];
        free(mapped);
        return array;
    }
    else return @[];
}

@end
