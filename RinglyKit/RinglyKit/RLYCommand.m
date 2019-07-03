#import "RLYCommand+Internal.h"

#pragma mark - Data Representations
NSData *RLYCommandDataRepresentation(id<RLYCommand> command)
{
    // start with the base data for all commands
    uint8_t bytes[] = { 0, [command type] };
    NSMutableData *data = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
    
    // append the length of the extra subclass data, even if it's nil (so, length = 0)
    NSData *extra = [command respondsToSelector:@selector(extraData)] ? command.extraData : nil;
    uint8_t length[] = { (uint8_t)extra.length };
    [data appendBytes:length length:sizeof(length)];
    
    // if we actually have extra data, append it
    if (extra)
    {
        [data appendBytes:extra.bytes length:extra.length];
    }
    
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    return [NSData dataWithData:data];
}
