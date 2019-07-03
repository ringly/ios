#import <RinglyKit/RLYFunctions.h>
#import <XCTest/XCTest.h>

@interface RLYStringFittingTests : XCTestCase

@end

@implementation RLYStringFittingTests

-(void)testFitting
{
    NSString *input = @"Hello";
    
    XCTAssertEqualObjects(@"Hello", RLYStringFittingInUTF8Bytes(input, 5));
    XCTAssertEqualObjects(@"Hell", RLYStringFittingInUTF8Bytes(input, 4));
    XCTAssertEqualObjects(@"Hel", RLYStringFittingInUTF8Bytes(input, 3));
    XCTAssertEqualObjects(@"He", RLYStringFittingInUTF8Bytes(input, 2));
    XCTAssertEqualObjects(@"H", RLYStringFittingInUTF8Bytes(input, 1));
    XCTAssertEqualObjects(@"", RLYStringFittingInUTF8Bytes(input, 0));
}

-(void)testEmoji
{
    NSUInteger fireLength = [@"🔥" lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSString *input = @"🔥🔥🔥";
    
    XCTAssertEqualObjects(@"🔥🔥🔥", RLYStringFittingInUTF8Bytes(input, fireLength * 3));
    XCTAssertEqualObjects(@"🔥🔥", RLYStringFittingInUTF8Bytes(input, fireLength * 2));
    XCTAssertEqualObjects(@"🔥", RLYStringFittingInUTF8Bytes(input, fireLength));
    XCTAssertEqualObjects(@"", RLYStringFittingInUTF8Bytes(input, 0));
}

-(void)testEmojiAndText
{
    NSString *input = @"Hello🌎";
    
    XCTAssertEqualObjects(@"Hello", RLYStringFittingInUTF8Bytes(input, 6));
}

@end
