#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYANCSV1Parser.h>
#import <RinglyKit/RLYFunctions.h>
#import <XCTest/XCTest.h>

NSData *NullTerminate(NSData *input)
{
    NSMutableData *data = [input mutableCopy];
    
    char terminator = '\0';
    [data appendBytes:&terminator length:sizeof(terminator)];
    
    return data;
}

@interface RLYANCSV1ParserTests : XCTestCase <RLYANCSV1ParserDelegate>

@property (nonatomic, strong) RLYANCSV1Parser *parser;
@property (nonatomic, strong) RLYANCSNotification *notification;
@property (nonatomic, strong) NSError *error;

@end

@implementation RLYANCSV1ParserTests

#pragma mark - Setup and Teardown
-(void)setUp
{
    [super setUp];
    
    self.parser = [RLYANCSV1Parser new];
    self.parser.delegate = self;
}

-(void)tearDown
{
    [super tearDown];
    
    self.parser.delegate = nil;
    self.parser = nil;
    self.notification = nil;
    self.error = nil;
}

#pragma mark - Tests
-(void)testScanHeader
{
    XCTAssertEqualObjects(RLYScanANCSV1Header([@"0,test" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"0," dataUsingEncoding:NSUTF8StringEncoding]);
    
    XCTAssertEqualObjects(RLYScanANCSV1Header([@"10,test" dataUsingEncoding:NSUTF8StringEncoding]),
                          [@"10," dataUsingEncoding:NSUTF8StringEncoding]);
    
    XCTAssertNil(RLYScanANCSV1Header([@"0test" dataUsingEncoding:NSUTF8StringEncoding]));
}

-(void)testSuccessfulParse
{
    [self.parser appendData:NullTerminate([@"0,4" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:[@"0,com.ringly." dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Ringly" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Testing" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,011200000" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNotNil(self.notification);
    XCTAssertNil(self.error);
    
    XCTAssertEqualObjects(self.notification.applicationIdentifier, @"com.ringly.Ringly");
    XCTAssertEqualObjects(self.notification.title, @"Testing");
    XCTAssertEqual(self.notification.category, RLYANCSCategorySocial);
}

-(void)testTwoCharacterHeader
{
    [self.parser appendData:NullTerminate([@"10,4" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:[@"10,com.ringly." dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"10,Ringly" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"10,Testing" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"10,011200000" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNotNil(self.notification);
    XCTAssertNil(self.error);
    
    XCTAssertEqualObjects(self.notification.applicationIdentifier, @"com.ringly.Ringly");
    XCTAssertEqualObjects(self.notification.title, @"Testing");
    XCTAssertEqual(self.notification.category, RLYANCSCategorySocial);
}

-(void)testEmptyDate
{
    [self.parser appendData:NullTerminate([@"0,4" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:[@"0,com.ringly." dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Ringly" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Testing" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,\0\0\0\0\0\0\0\00" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNotNil(self.notification);
    XCTAssertNil(self.error);
    
    XCTAssertEqual(self.notification.date, nil);
}

-(void)testTerminatorBreak
{
    [self.parser appendData:NullTerminate([@"0,4" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:[@"0,com.ringly." dataUsingEncoding:NSUTF8StringEncoding]];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Ringly" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,Test\0ing" dataUsingEncoding:NSUTF8StringEncoding])];
    XCTAssertNil(self.notification);
    
    [self.parser appendData:NullTerminate([@"0,011200000" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNotNil(self.notification);
    XCTAssertNil(self.error);
    
    XCTAssertEqualObjects(self.notification.applicationIdentifier, @"com.ringly.Ringly");
    XCTAssertEqualObjects(self.notification.title, @"Test");
    XCTAssertEqual(self.notification.category, RLYANCSCategorySocial);
}

-(void)testInvalidIdentifier
{
    [self.parser appendData:NullTerminate([@"0,4" dataUsingEncoding:NSUTF8StringEncoding])];
    [self.parser appendData:NullTerminate([@"1,4" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNil(self.notification);
    XCTAssertNotNil(self.error);
    
    XCTAssertEqualObjects(self.error.domain, RLYANCSV1ErrorDomain);
    XCTAssertEqual(self.error.code, RLYANCSV1ErrorCodeDifferentHeader);
    
    self.error = nil;
    
    [self.parser appendData:[@"1,com.ringly." dataUsingEncoding:NSUTF8StringEncoding]];
    [self.parser appendData:NullTerminate([@"1,Ringly" dataUsingEncoding:NSUTF8StringEncoding])];
    [self.parser appendData:NullTerminate([@"1,Testing" dataUsingEncoding:NSUTF8StringEncoding])];
    [self.parser appendData:NullTerminate([@"1,011200000" dataUsingEncoding:NSUTF8StringEncoding])];
    
    XCTAssertNotNil(self.notification);
    XCTAssertNil(self.error);
    
    XCTAssertEqualObjects(self.notification.applicationIdentifier, @"com.ringly.Ringly");
    XCTAssertEqualObjects(self.notification.title, @"Testing");
    XCTAssertEqual(self.notification.category, RLYANCSCategorySocial);
}

-(void)testInvalidHeader
{
    [self.parser appendData:NullTerminate([@"0,4" dataUsingEncoding:NSUTF8StringEncoding])];
    [self.parser appendData:[@"0" dataUsingEncoding:NSUTF8StringEncoding]];
    
    XCTAssertNil(self.notification);
    XCTAssertNotNil(self.error);
    
    XCTAssertEqualObjects(self.error.domain, RLYANCSV1ErrorDomain);
    XCTAssertEqual(self.error.code, RLYANCSV1ErrorCodeInvalidHeader);
}

#pragma mark - ANCS Version 1 Parser Delegate
-(void)ANCSV1Parser:(RLYANCSV1Parser *)parser parsedNotification:(RLYANCSNotification *)notification
{
    self.notification = notification;
}

-(void)ANCSV1Parser:(RLYANCSV1Parser *)parser failedToParseNotificationWithError:(NSError *)error
{
    self.error = error;
}

@end
