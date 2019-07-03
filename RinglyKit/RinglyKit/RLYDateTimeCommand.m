#import "RLYCommand+Internal.h"
#import "RLYDateTimeCommand.h"

@implementation RLYDateTimeCommand

-(instancetype)init
{
    return self = [self initWithDate:[NSDate date]];
}

-(instancetype)initWithDate:(NSDate*)date
{
    self = [super init];
    
    if (self)
    {
        _date = date;
    }
    
    return self;
}

-(RLYCommandType)type
{
    return RLYCommandTypePresetDateTime;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"Date %@", _date];
}

-(NSData*)extraData
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd'T'HHmm"];

    NSMutableData *data = [NSMutableData dataWithCapacity:14];
    [data appendData:[[dateFormatter stringFromDate:_date] dataUsingEncoding:NSUTF8StringEncoding]];
    
    unsigned char nullTerminator = 0;
    [data appendBytes:&nullTerminator length:1];
    
    return data;
}

@end
