#import <RinglyKit/RLYFunctions.h>
#import <RinglyExtensions/RinglyExtensions-Swift.h>
#import "NSString+VersionNumbers.h"

@implementation NSString (VersionNumbers)

#pragma mark - Version Numbers
-(NSArray*)rly_versionNumberComponents
{
    return RLYVersionNumberComponents(self);
}

-(NSComparisonResult)rly_compareVersionNumbers:(NSString *)string
{
    return RLYCompareVersionNumbers(self, string);
}

-(NSString*)rly_versionNumberWithSeparator:(NSString*)separator
{
    return [self.rly_versionNumberComponents componentsJoinedByString:separator];
}

-(BOOL)rly_versionNumberIsAfter:(NSString*)start andBefore:(NSString*)end
{
    return [start rly_compareVersionNumbers:self] == NSOrderedAscending
        && [self rly_compareVersionNumbers:end] == NSOrderedAscending;
}

-(BOOL)rly_versionNumberIs:(NSString*)start
{
    return [start rly_compareVersionNumbers:self] == NSOrderedAscending;
}

@end
