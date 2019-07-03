#import "RLYCommand+Internal.h"
#import "RLYContactSettingsCommand.h"
#import "RLYFunctions.h"

static size_t const RLYContactSettingsCommandMaxNameBytes = 100;

@interface RLYContactSettingsCommand ()
{
@private
    RLYColor _color;
}

@end

@implementation RLYContactSettingsCommand

#pragma mark - Initialization
-(instancetype)initWithMode:(RLYSettingsCommandMode)mode
                contactName:(NSString*)contactName
                      color:(RLYColor)color
{
    self = [super init];
    
    if (self)
    {
        _mode = mode;
        _contactName = contactName;
        _color = color;
    }
    
    return self;
}

#pragma mark - Creation
+(instancetype)addCommandWithContactName:(NSString *)contactName color:(RLYColor)color
{
    return [[self alloc] initWithMode:RLYSettingsCommandModeAdd contactName:contactName color:color];
}

+(instancetype)deleteCommandWithContactName:(NSString *)contactName
{
    return [[self alloc] initWithMode:RLYSettingsCommandModeDelete
                          contactName:contactName
                                color:RLYColorNone];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(%@ contact %@, color = %@)",
            RLYSettingsCommandModeToString(_mode),
            _contactName,
            RLYColorToString(_color)];
}

#pragma mark - Command Data
-(RLYCommandType)type
{
    return RLYCommandTypePresetContactSettings;
}

-(NSData*)extraData
{
    // begin with the contact name, converted to bytes
    NSString *fittingName = RLYStringFittingInUTF8Bytes(_contactName, RLYContactSettingsCommandMaxNameBytes);
    NSData *nameData = [fittingName dataUsingEncoding:NSUTF8StringEncoding];
    
    // add the name length to the front of the name data
    NSMutableData *data = nameData.mutableCopy;
    
    uint8_t dataLength = (uint8_t)data.length;
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:&dataLength length:1];
    
    // add the mode flag to the front of the data
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:&_mode length:1];
    
    if (_mode == RLYSettingsCommandModeAdd)
    {
        uint8_t bytes[] = {
            _color.red,
            _color.green,
            _color.blue
        };
        
        [data appendBytes:bytes length:sizeof(bytes)];
    }
    
    return data;
}

@end
