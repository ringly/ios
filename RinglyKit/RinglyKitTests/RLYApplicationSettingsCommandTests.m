#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYApplicationSettingsCommandTests : XCTestCase

@end

@implementation RLYApplicationSettingsCommandTests

-(void)testAdd
{
    RLYColor color = RLYColorMake(100, 101, 102);
    RLYVibration vibration = RLYVibrationOnePulse;
    
    RLYApplicationSettingsCommand *add =
        [RLYApplicationSettingsCommand addCommandWithApplicationIdentifier:@"com.ringly.ringly"
                                                                     color:color
                                                                 vibration:vibration];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetApplicationSettings,
        23, // data length
        0, // app updated
        17, // name length
        'c', 'o', 'm', '.', 'r', 'i', 'n', 'g', 'l', 'y', '.', 'r', 'i', 'n', 'g', 'l', 'y',
        color.red,
        color.green,
        color.blue,
        (uint8_t)RLYVibrationToCount(vibration)
    };
    
    NSData *data = RLYCommandDataRepresentation(add);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testDelete
{
    RLYApplicationSettingsCommand *delete =
        [RLYApplicationSettingsCommand deleteCommandWithApplicationIdentifier:@"com.ringly.ringly"];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetApplicationSettings,
        19, // data length
        1, // app removed
        17, // name length
        'c', 'o', 'm', '.', 'r', 'i', 'n', 'g', 'l', 'y', '.', 'r', 'i', 'n', 'g', 'l', 'y'
    };
    
    NSData *data = RLYCommandDataRepresentation(delete);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testIdentifierTooLong
{
    NSString *identifier = @"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
    
    RLYColor color = RLYColorMake(100, 101, 102);
    RLYVibration vibration = RLYVibrationOnePulse;
    
    RLYApplicationSettingsCommand *command =
        [RLYApplicationSettingsCommand addCommandWithApplicationIdentifier:identifier
                                                                     color:color
                                                                 vibration:vibration];
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetApplicationSettings,
        106, // data length
        0, // app updated
        100, // name length
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        color.red,
        color.green,
        color.blue,
        (uint8_t)RLYVibrationToCount(vibration)
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:bytes length:sizeof(bytes)]);
}

-(void)testIdentifierTooLongEmoji
{
    NSString *identifier = @"012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678😬";
    
    RLYColor color = RLYColorMake(100, 101, 102);
    RLYVibration vibration = RLYVibrationOnePulse;
    
    RLYApplicationSettingsCommand *command =
        [RLYApplicationSettingsCommand addCommandWithApplicationIdentifier:identifier
                                                                     color:color
                                                                 vibration:vibration];
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetApplicationSettings,
        105, // data length
        0, // app updated
        99, // name length
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '0', '1', '2', '3', '4', '5', '6', '7', '8',
        color.red,
        color.green,
        color.blue,
        (uint8_t)RLYVibrationToCount(vibration)
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:bytes length:sizeof(bytes)]);
}

@end
