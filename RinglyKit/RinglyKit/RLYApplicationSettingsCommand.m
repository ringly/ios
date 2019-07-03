#import "RLYApplicationSettingsCommand.h"
#import "RLYCommand+Internal.h"
#import "RLYFunctions.h"

static size_t const RLYApplicationSettingsCommandMaxNameBytes = 100;

@interface RLYApplicationSettingsCommand ()
{
@private
    RLYColor _color;
    RLYVibration _vibration;
}

@end

@implementation RLYApplicationSettingsCommand

#pragma mark - Initialization
-(instancetype)initWithMode:(RLYSettingsCommandMode)mode
      applicationIdentifier:(NSString*)applicationIdentifier
                      color:(RLYColor)color
                  vibration:(RLYVibration)vibration
{
    self = [super init];
    
    if (self)
    {
        _mode = mode;
        _applicationIdentifier = applicationIdentifier;
        _color = color;
        _vibration = vibration;
    }
    
    return self;
}

#pragma mark - Creation
+(instancetype)addCommandWithApplicationIdentifier:(NSString *)applicationIdentifier
                                             color:(RLYColor)color
                                         vibration:(RLYVibration)vibration
{
    return [[self alloc] initWithMode:RLYSettingsCommandModeAdd
                applicationIdentifier:applicationIdentifier
                                color:color
                            vibration:vibration];
}

+(instancetype)deleteCommandWithApplicationIdentifier:(NSString *)applicationIdentifier
{
    return [[self alloc] initWithMode:RLYSettingsCommandModeDelete
                applicationIdentifier:applicationIdentifier
                                color:RLYColorNone
                            vibration:RLYVibrationNone];
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(%@ application %@, color: %@, vibration: %@)",
            RLYSettingsCommandModeToString(_mode),
            _applicationIdentifier,
            RLYColorToString(_color),
            RLYVibrationToString(_vibration)];
}

#pragma mark - Command Data
-(RLYCommandType)type
{
    return RLYCommandTypePresetApplicationSettings;
}

-(NSData*)extraData
{
    // begin with the application identifier, converted to bytes
    NSString *fit = RLYStringFittingInUTF8Bytes(_applicationIdentifier, RLYApplicationSettingsCommandMaxNameBytes);
    NSData *identifierData = [fit dataUsingEncoding:NSUTF8StringEncoding];
    
    // add the name length to the front of the name data
    NSMutableData *data = identifierData.mutableCopy;
    
    uint8_t dataLength = (uint8_t)data.length;
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:&dataLength length:1];
    
    // add the mode flag to the front of the data
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:&_mode length:1];
    
    if (_mode == RLYSettingsCommandModeAdd)
    {
        uint8_t bytes[] = {
            _color.red,
            _color.green,
            _color.blue,
            (uint8_t)RLYVibrationToCount(_vibration)
        };
        
        [data appendBytes:bytes length:sizeof(bytes)];
    }
    
    return data;
}

@end
