#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYCommand+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYNoActionCommandTests : XCTestCase

@end

@implementation RLYNoActionCommandTests

-(void)testNoActionCommand
{
    uint8_t bytes[] = {
        0, RLYCommandTypePresetLEDVibration, 0
    };
    
    NSData *data = [NSData dataWithBytes:&bytes length:sizeof(bytes)];
    
    XCTAssertEqualObjects(RLYCommandDataRepresentation([RLYNoActionCommand new]), data);
}

@end
