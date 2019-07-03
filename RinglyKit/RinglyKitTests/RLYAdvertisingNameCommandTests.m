#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYAdvertisingNameCommandTests : XCTestCase

@end

@implementation RLYAdvertisingNameCommandTests

-(void)testNotDiamondClub
{
    RLYAdvertisingNameCommand *command = [[RLYAdvertisingNameCommand alloc] initWithShortName:@"DAYD" diamondClub:NO];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetAdvertisingName,
        7,
        '-', ' ', 'D', 'A', 'Y', 'D', '\0'
    };
    
    NSData *data = RLYCommandDataRepresentation(command);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

-(void)testDiamondClub
{
    RLYAdvertisingNameCommand *command = [[RLYAdvertisingNameCommand alloc] initWithShortName:@"DAYD" diamondClub:YES];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetAdvertisingName,
        7,
        '*', ' ', 'D', 'A', 'Y', 'D', '\0'
    };
    
    NSData *data = RLYCommandDataRepresentation(command);
    NSData *expected = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    XCTAssertTrue([data isEqualToData:expected], "%@ should be equal to the expected value %@", data, expected);
}

@end
