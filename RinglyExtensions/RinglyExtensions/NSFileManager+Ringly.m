#import "NSFileManager+Ringly.h"

@implementation NSFileManager (Ringly)

-(NSString*)rly_documentsPath
{
    static NSString *documentsPath = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    });
    
    return documentsPath;
}

-(NSString*)rly_cachesPath
{
    static NSString *cachesPath = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    });
    
    return cachesPath;
}

-(NSURL*)rly_documentsURL
{
    return [NSURL fileURLWithPath:self.rly_documentsPath];
}

-(NSURL*)rly_cachesURL
{
    return [NSURL fileURLWithPath:self.rly_cachesPath];
}

-(NSString*)rly_documentsFileWithName:(NSString*)filename
{
    return [self.rly_documentsPath stringByAppendingPathComponent:filename];
}

-(BOOL)rly_directoryExistsAtPath:(NSString*)path
{
    BOOL directory = NO;
    
    if ([self fileExistsAtPath:path isDirectory:&directory])
    {
        return directory;
    }
    else
    {
        return NO;
    }
}

@end
