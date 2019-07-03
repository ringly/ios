#import "Functions.h"

void RLYDispatchAfterMain(NSTimeInterval after, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

#ifdef DEBUG
NSString *RLYJSONString(id JSONObject)
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}
#endif
