#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYContactsSettingsCommandTests : XCTestCase

@end

@implementation RLYContactsSettingsCommandTests

-(void)testAdd
{
    RLYColor color = RLYColorMake(100, 101, 102);
    
    RLYContactSettingsCommand *add = [RLYContactSettingsCommand addCommandWithContactName:@"Foo Bar" color:color];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactSettings,
        12, // data length
        0, // app updated
        7, // name length
        'F', 'o', 'o', ' ', 'B', 'a', 'r',
        color.red,
        color.green,
        color.blue,
    };
    
    NSData *data = RLYCommandDataRepresentation(add);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testDelete
{
    RLYContactSettingsCommand *delete = [RLYContactSettingsCommand deleteCommandWithContactName:@"Foo Bar"];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactSettings,
        9, // data length
        1, // app removed
        7, // name length
        'F', 'o', 'o', ' ', 'B', 'a', 'r'
    };
    
    NSData *data = RLYCommandDataRepresentation(delete);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testNameTooLong
{
    NSString *name = @"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
    
    RLYColor color = RLYColorMake(100, 101, 102);
    RLYContactSettingsCommand *command = [RLYContactSettingsCommand addCommandWithContactName:name color:color];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactSettings,
        105, // data length
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
        color.blue
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:bytes length:sizeof(bytes)]);
}

-(void)testNameTooLongEmoji
{
    NSString *name = @"012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678😬";
    
    RLYColor color = RLYColorMake(100, 101, 102);
    RLYContactSettingsCommand *command = [RLYContactSettingsCommand addCommandWithContactName:name color:color];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactSettings,
        104, // data length
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
        color.blue
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:bytes length:sizeof(bytes)]);
}

@end
