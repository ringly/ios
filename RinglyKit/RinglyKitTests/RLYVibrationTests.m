#import <RinglyKit/RinglyKit.h>
#import <XCTest/XCTest.h>

@interface RLYVibrationTests : XCTestCase

@end

@implementation RLYVibrationTests

-(void)testVibrationFromCount
{
    XCTAssertEqual(RLYVibrationFromCount(0), RLYVibrationNone);
    XCTAssertEqual(RLYVibrationFromCount(1), RLYVibrationOnePulse);
    XCTAssertEqual(RLYVibrationFromCount(2), RLYVibrationTwoPulses);
    XCTAssertEqual(RLYVibrationFromCount(3), RLYVibrationThreePulses);
    XCTAssertEqual(RLYVibrationFromCount(4), RLYVibrationFourPulses);
}

-(void)testVibrationToCount
{
    XCTAssertEqual(RLYVibrationToCount(RLYVibrationNone), 0);
    XCTAssertEqual(RLYVibrationToCount(RLYVibrationOnePulse), 1);
    XCTAssertEqual(RLYVibrationToCount(RLYVibrationTwoPulses), 2);
    XCTAssertEqual(RLYVibrationToCount(RLYVibrationThreePulses), 3);
    XCTAssertEqual(RLYVibrationToCount(RLYVibrationFourPulses), 4);
}

@end
