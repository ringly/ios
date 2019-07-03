#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYANCSTimeoutAlertCommandTests : XCTestCase

@end

@implementation RLYANCSTimeoutAlertCommandTests

-(void)testEnabled
{
    RLYANCSTimeoutAlertCommand *command = [[RLYANCSTimeoutAlertCommand alloc] initWithEnabled:YES];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetANCSTimeoutAlert,
        1,
        1
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:&bytes length:sizeof(bytes)]);
}

-(void)testDisabled
{
    RLYANCSTimeoutAlertCommand *command = [[RLYANCSTimeoutAlertCommand alloc] initWithEnabled:NO];
    
    uint8_t bytes[] = {
        0,
        RLYCommandTypePresetANCSTimeoutAlert,
        1,
        0xff
    };
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation(command), [NSData dataWithBytes:&bytes length:sizeof(bytes)]);
}

@end
