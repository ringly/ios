#import <RinglyKit/RLYFunctions.h>
#import <XCTest/XCTest.h>

@interface RLYDataStringFunctionsTests : XCTestCase

@end

@implementation RLYDataStringFunctionsTests

#pragma mark - First Null
-(void)testSubdataToFirstNulll
{
    // nulls in the middle crop to the character before them
    XCTAssertEqualObjects(RLYSubdataToFirstNull([@"Test\0Test" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"Test" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // nulls at the end are removed
    XCTAssertEqualObjects(RLYSubdataToFirstNull([@"Test\0" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"Test" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // if multiple nulls are present, data is cropped to the first occurence
    XCTAssertEqualObjects(RLYSubdataToFirstNull([@"Te\0st\0Test" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"Te" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // a leading null results in an empty data
    XCTAssertEqualObjects(RLYSubdataToFirstNull([@"\0Test\0Test" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"" dataUsingEncoding:NSUTF8StringEncoding]);
}

#pragma mark - UTF-8 Prefix
-(void)testFindValidUTF8Prefix
{
    NSString *string = @"test😐";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // with the full data, we should get the full string back
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix(data), string);
    
    // with split character, we should not get that character back
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 1)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 2)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 3)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 4)]), @"test");
    
    // after that, characters should start dropping again
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 5)]), @"tes");
}

-(void)testFindValidUTF8PrefixEmptyString
{
    NSString *string = @"😐";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // with the full data, we should get the full string back
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix(data), string);
    
    // with one-character strings that have been cropped, should return an empty string
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 1)]), @"");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 2)]), @"");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 3)]), @"");
    XCTAssertEqualObjects(RLYFindValidUTF8Prefix([data subdataWithRange:NSMakeRange(0, data.length - 4)]), @"");
}

#pragma mark - UTF-8 Suffix
-(void)testFindValidUTF8Suffix
{
    NSString *string = @"😐test";
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // with the full data, we should get the full string back
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix(data), string);
    
    // with split character, we should not get that character back
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix([data subdataWithRange:NSMakeRange(1, data.length - 1)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix([data subdataWithRange:NSMakeRange(2, data.length - 2)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix([data subdataWithRange:NSMakeRange(3, data.length - 3)]), @"test");
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix([data subdataWithRange:NSMakeRange(4, data.length - 4)]), @"test");
    
    // after that, characters should start dropping again
    XCTAssertEqualObjects(RLYFindValidUTF8Suffix([data subdataWithRange:NSMakeRange(5, data.length - 5)]), @"est");
}

@end
