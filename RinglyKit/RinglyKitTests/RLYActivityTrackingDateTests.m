#import <XCTest/XCTest.h>
#import <RinglyKit/RinglyKit.h>

@interface RLYActivityTrackingDateTests : XCTestCase

@end

@implementation RLYActivityTrackingDateTests

#pragma mark - Interval Initialization
-(void)testIntervalInitialization
{
    XCTAssertNotNil([RLYActivityTrackingDate dateWithMinute:RLYActivityTrackingMinuteMin error:nil]);
    XCTAssertNotNil([RLYActivityTrackingDate dateWithMinute:1000 error:nil]);
    XCTAssertNotNil([RLYActivityTrackingDate dateWithMinute:RLYActivityTrackingMinuteMax error:nil]);
}

-(void)testIntervalTooLateInitialization
{
    NSError *error = nil;
    XCTAssertNil([RLYActivityTrackingDate dateWithMinute:RLYActivityTrackingMinuteMax + 1 error:&error]);
    XCTAssertEqualObjects(error.domain, RLYActivityTrackingDateErrorDomain);
    XCTAssertEqual(error.code, RLYActivityTrackingDateErrorCodeIntervalGreaterThanMaximum);
}

#pragma mark - Timestamp Initialization
-(void)testTimestampInitialization
{
    RLYActivityTrackingDate *date =
        [RLYActivityTrackingDate dateWithTimestamp:RLYActivityTrackingDateReferenceTimestamp + 60 error:nil];

    XCTAssertNotNil(date);
    XCTAssertEqual(date.minute, (RLYActivityTrackingMinute)1);

    RLYActivityTrackingDate *oneMinute =
        [RLYActivityTrackingDate dateWithTimestamp:RLYActivityTrackingDateReferenceTimestamp + 120 error:nil];

    XCTAssertNotNil(oneMinute);
    XCTAssertEqual(oneMinute.minute, (RLYActivityTrackingMinute)2);

    RLYActivityTrackingDate *oneMinuteThirty =
        [RLYActivityTrackingDate dateWithTimestamp:RLYActivityTrackingDateReferenceTimestamp + 150 error:nil];

    XCTAssertNotNil(oneMinuteThirty);
    XCTAssertEqual(oneMinuteThirty.minute, (RLYActivityTrackingMinute)2);
}

-(void)testTimestampTooEarlyInitialization
{
    NSError *error = nil;

    RLYActivityTrackingDate *date =
        [RLYActivityTrackingDate dateWithTimestamp:RLYActivityTrackingDateReferenceTimestamp error:&error];

    XCTAssertNil(date);
    XCTAssertEqualObjects(error.domain, RLYActivityTrackingDateErrorDomain);
    XCTAssertEqual(error.code, RLYActivityTrackingDateErrorCodeIntervalLessThanMinimum);
}

#pragma mark - Date Initialization
-(void)testDateInitialization
{
    NSDate *reference = [NSDate dateWithTimeIntervalSince1970:RLYActivityTrackingDateReferenceTimestamp + 60];
    RLYActivityTrackingDate *date = [RLYActivityTrackingDate dateWithDate:reference error:nil];

    XCTAssertNotNil(date);
    XCTAssertEqual(date.minute, (RLYActivityTrackingMinute)1);

    RLYActivityTrackingDate *oneMinute =
        [RLYActivityTrackingDate dateWithDate:[reference dateByAddingTimeInterval:60] error:nil];

    XCTAssertNotNil(oneMinute);
    XCTAssertEqual(oneMinute.minute, (RLYActivityTrackingMinute)2);

    RLYActivityTrackingDate *oneMinuteThirty =
        [RLYActivityTrackingDate dateWithDate:[reference dateByAddingTimeInterval:90] error:nil];

    XCTAssertNotNil(oneMinuteThirty);
    XCTAssertEqual(oneMinuteThirty.minute, (RLYActivityTrackingMinute)2);
}

#pragma mark - Boundary Dates
-(void)testBoundaryDates
{
    XCTAssertNotNil([RLYActivityTrackingDate minimumDate]);
    XCTAssertNotNil([RLYActivityTrackingDate maximumDate]);
}

#pragma mark - Equality
-(void)testEquality
{
    RLYActivityTrackingDate *date1 = [RLYActivityTrackingDate dateWithMinute:10 error:nil];
    RLYActivityTrackingDate *date2 = [RLYActivityTrackingDate dateWithMinute:10 error:nil];

    XCTAssertNotNil(date1);
    XCTAssertNotNil(date2);
    XCTAssertEqualObjects(date1, date2);
}

-(void)testDateInequality
{
    RLYActivityTrackingDate *date1 = [RLYActivityTrackingDate dateWithMinute:10 error:nil];
    RLYActivityTrackingDate *date2 = [RLYActivityTrackingDate dateWithMinute:11 error:nil];

    XCTAssertNotNil(date1);
    XCTAssertNotNil(date2);
    XCTAssertNotEqualObjects(date1, date2);
}

-(void)testNilInequality
{
    RLYActivityTrackingDate *date = [RLYActivityTrackingDate dateWithMinute:10 error:nil];

    XCTAssertNotNil(date);
    XCTAssertNotEqualObjects(date, nil);
}

-(void)testOtherClassInequality
{
    RLYActivityTrackingDate *date = [RLYActivityTrackingDate dateWithMinute:10 error:nil];

    XCTAssertNotNil(date);
    XCTAssertNotEqualObjects(date, @"Test");
}

#pragma mark - Byte Representations
-(void)testByteRepresentationRoundtripFromBytes
{
    RLYActivityTrackingMinuteBytes bytes = RLYActivityTrackingMinuteBytesMake(55, 155, 255);
    RLYActivityTrackingMinuteBytes roundtrip = RLYActivityTrackingMinuteBytesFromMinute(
        RLYActivityTrackingMinuteBytesToMinute(bytes)
    );

    XCTAssertEqual(bytes.first, roundtrip.first);
    XCTAssertEqual(bytes.second, roundtrip.second);
    XCTAssertEqual(bytes.third, roundtrip.third);
}

-(void)testByteRepresentationRoundtripFromInterval
{
    RLYActivityTrackingMinute max = RLYActivityTrackingMinuteMax;
    RLYActivityTrackingMinute maxRoundtrip = RLYActivityTrackingMinuteBytesToMinute(
        RLYActivityTrackingMinuteBytesFromMinute(max)
    );

    XCTAssertEqual(max, maxRoundtrip);

    RLYActivityTrackingMinute min = RLYActivityTrackingMinuteMin;
    RLYActivityTrackingMinute minRoundtrip = RLYActivityTrackingMinuteBytesToMinute(
        RLYActivityTrackingMinuteBytesFromMinute(min)
    );

    XCTAssertEqual(min, minRoundtrip);

    RLYActivityTrackingMinute mid = RLYActivityTrackingMinuteMin + RLYActivityTrackingMinuteMax / 2;
    RLYActivityTrackingMinute midRoundtrip = RLYActivityTrackingMinuteBytesToMinute(
        RLYActivityTrackingMinuteBytesFromMinute(mid)
    );

    XCTAssertEqual(mid, midRoundtrip);
}

@end
