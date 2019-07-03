#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYANCSV2Parser.h>
#import <XCTest/XCTest.h>

@interface RLYANCSV2ParserTests : XCTestCase
@end

@implementation RLYANCSV2ParserTests

-(void)testSuccessfulParse
{
    NSUInteger notificationAttributeCount = 8;
    NSUInteger applicationAttributeCount = 1;
    
    NSString *base64 = @"ABQAAAAAEwBjb20uYXBwbGUuTW9iaWxlU01TAQwATmF0ZSBTdGVkbWFuAgAAAw4AaGFzbGhrZmpkYXNoZmEEAgAxNAUPADIwMTUxMDI4VDEyMDAyMQYAAAcFAENsZWFyAWNvbS5hcHBsZS5Nb2JpbGVTTVMAAAgATWVzc2FnZXMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
    
    XCTAssertNotNil(data);
    
    NSError *error = nil;
    RLYANCSNotification *notification = [RLYANCSV2Parser parseData:data
                                    withNotificationAttributeCount:notificationAttributeCount
                                         applicationAttributeCount:applicationAttributeCount
                                                             error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(notification);

    XCTAssertEqualObjects(notification.applicationIdentifier, @"com.apple.MobileSMS");
    XCTAssertEqualObjects(notification.title, @"Nate Stedman");
}

-(void)testErrorData
{
    NSString *base64 = @"abcd";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];

    NSError *error = nil;

    RLYANCSNotification *notification = [RLYANCSV2Parser parseData:data
                                    withNotificationAttributeCount:1
                                         applicationAttributeCount:1
                                                             error:&error];

    XCTAssertNil(notification);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.userInfo[RLYANCSV2DataErrorKey], [data description]);
}

@end
