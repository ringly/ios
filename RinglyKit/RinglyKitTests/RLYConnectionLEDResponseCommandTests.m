#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYConnectionLEDResponseCommandTests : XCTestCase

@end

@implementation RLYConnectionLEDResponseCommandTests

-(void)testEnabled
{
    RLYConnectionLEDResponseCommand *command = [[RLYConnectionLEDResponseCommand alloc] initWithEnabled:YES];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetConnectionLEDResponse,
        1,
        1
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:&bytes length:sizeof(bytes)]);
}

-(void)testDisabled
{
    RLYConnectionLEDResponseCommand *command = [[RLYConnectionLEDResponseCommand alloc] initWithEnabled:NO];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetConnectionLEDResponse,
        1,
        0xff
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:&bytes length:sizeof(bytes)]);
}

@end
