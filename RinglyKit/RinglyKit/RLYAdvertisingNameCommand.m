#import "RLYAdvertisingNameCommand.h"
#import "RLYCommand+Internal.h"

@implementation RLYAdvertisingNameCommand

#pragma mark - Creation
-(id)initWithShortName:(NSString *)shortName diamondClub:(BOOL)diamondClub
{
    self = [super init];
    
    if (self)
    {
        _shortName = shortName;
        _diamondClub = diamondClub;
    }
    
    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"Advertising Name (%@)", self.fullAdvertisingName];
}

#pragma mark - Data
-(NSString*)fullAdvertisingName
{
    return [NSString stringWithFormat:@"%@ %@", _diamondClub ? @"*" : @"-", _shortName];
}

-(RLYCommandType)type
{
    return RLYCommandTypePresetAdvertisingName;
}

-(NSData*)extraData
{
    NSMutableData *nameData = [[self.fullAdvertisingName dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    unsigned char nullTerminator = 0;
    [nameData appendBytes:&nullTerminator length:1];

    return nameData;
}

@end
