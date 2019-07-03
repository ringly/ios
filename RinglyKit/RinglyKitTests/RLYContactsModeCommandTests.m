#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYContactsModeCommandTests : XCTestCase

@end

@implementation RLYContactsModeCommandTests

-(void)testAdditionalColor
{
    RLYContactsModeCommand *command = [[RLYContactsModeCommand alloc] initWithMode:RLYContactsModeAdditionalColor];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactsMode,
        1,
        0
    };
    
    NSData *data = RLYCommandDataRepresentation(command);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testContactsOnly
{
    RLYContactsModeCommand *command = [[RLYContactsModeCommand alloc] initWithMode:RLYContactsModeContactsOnly];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactsMode,
        1,
        1
    };
    
    NSData *data = RLYCommandDataRepresentation(command);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testDisabled
{
    RLYContactsModeCommand *command = [[RLYContactsModeCommand alloc] initWithMode:RLYContactsModeDisabled];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetContactsMode,
        1,
        0xff
    };
    
    NSData *data = RLYCommandDataRepresentation(command);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

@end
