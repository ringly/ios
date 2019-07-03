#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYActivityTrackingUpdate+Internal.h>
#import <XCTest/XCTest.h>

@interface RLYActivityTrackingUpdateTests : XCTestCase

@end

@implementation RLYActivityTrackingUpdateTests

#pragma mark - Interval Parsing
-(void)testIntervalParsing
{
    uint8_t bytes[] = { 6, 235, 77 };
    XCTAssertEqual([RLYActivityTrackingUpdate intervalAtOffset:0 ofBytes:bytes],
                   (RLYActivityTrackingMinute)5106438);
}

#pragma mark - Data Parsing
-(void)testUpdateParsing
{
    uint8_t bytes[] = { 6, 235, 77, 100, 200 };

    NSError *error = nil;
    RLYActivityTrackingUpdate *update = [RLYActivityTrackingUpdate updateAtOffset:0 ofBytes:bytes withError:&error];

    XCTAssertEqual(update.date.minute, (RLYActivityTrackingMinute)5106438);
    XCTAssertEqual(update.walkingSteps, 100);
    XCTAssertEqual(update.runningSteps, 200);
}

#pragma mark - Update Parsing
-(void)testSuccessfulDataParsing
{
    uint8_t bytes[] = {
        6, 235, 77, 100, 200,
        6, 235, 78, 50, 150,
        6, 235, 79, 234, 134
    };

    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSMutableArray<RLYActivityTrackingUpdate*> *updates = [NSMutableArray arrayWithCapacity:3];

    [RLYActivityTrackingUpdate parseActivityTrackingCharacteristicData:data withUpdateCallback:^(RLYActivityTrackingUpdate * _Nonnull update) {
        [updates addObject:update];
    } errorCallback:^(NSError * _Nonnull error) {
        XCTFail();
    } completionCallback:^{
        XCTFail();
    }];

    XCTAssertEqual(updates.count, (NSUInteger)3);

    XCTAssertEqual(updates[0].date.minute, (RLYActivityTrackingMinute)5106438);
    XCTAssertEqual(updates[0].walkingSteps, 100);
    XCTAssertEqual(updates[0].runningSteps, 200);

    XCTAssertEqual(updates[1].date.minute, (RLYActivityTrackingMinute)5171974);
    XCTAssertEqual(updates[1].walkingSteps, 50);
    XCTAssertEqual(updates[1].runningSteps, 150);

    XCTAssertEqual(updates[2].date.minute, (RLYActivityTrackingMinute)5237510);
    XCTAssertEqual(updates[2].walkingSteps, 234);
    XCTAssertEqual(updates[2].runningSteps, 134);
}

-(void)testDataParsingCompletion
{
    NSData *data = [NSData data];

    __block NSInteger completed = 0;

    [RLYActivityTrackingUpdate parseActivityTrackingCharacteristicData:data withUpdateCallback:^(RLYActivityTrackingUpdate * _Nonnull update) {
        XCTFail();
    } errorCallback:^(NSError * _Nonnull error) {
        XCTFail();
    } completionCallback:^{
        completed++;
    }];

    XCTAssertEqual(completed, 1);
}

-(void)testDataParsingLengthError
{
    NSMutableArray<NSError*> *errors = [NSMutableArray array];

    uint8_t bytes[] = {
        6, 235, 77, 100, 200,
        6, 235, 78, 50,
        6, 235, 79, 234, 134
    };

    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    [RLYActivityTrackingUpdate parseActivityTrackingCharacteristicData:data withUpdateCallback:^(RLYActivityTrackingUpdate * _Nonnull update) {
        XCTFail();
    } errorCallback:^(NSError * _Nonnull error) {
        [errors addObject:error];
    } completionCallback:^{
        XCTFail();
    }];

    XCTAssertEqual(errors.count, (NSUInteger)1);
    XCTAssertEqualObjects(errors[0].domain, RLYActivityTrackingUpdateErrorDomain);
    XCTAssertEqual(errors[0].code, RLYActivityTrackingUpdateErrorCodeIncorrectDataLength);
}

-(void)testInlineDateParsing
{
    uint8_t bytes[] = {
        6, 235, 77, 100, 200,
        255, 255, 255, 50, 150,
        6, 235, 79, 234, 134
    };

    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:3];

    [RLYActivityTrackingUpdate parseActivityTrackingCharacteristicData:data withUpdateCallback:^(RLYActivityTrackingUpdate * _Nonnull update) {
        [events addObject:update];
    } errorCallback:^(NSError * _Nonnull error) {
        [events addObject:error];
    } completionCallback:^{
        XCTFail();
    }];

    XCTAssertEqual(events.count, (NSUInteger)3);
    XCTAssertTrue([events[0] isKindOfClass:[RLYActivityTrackingUpdate class]]);
    XCTAssertTrue([events[1] isKindOfClass:[RLYActivityTrackingUpdate class]]);
    XCTAssertTrue([events[2] isKindOfClass:[RLYActivityTrackingUpdate class]]);

    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[0] date].minute, (RLYActivityTrackingMinute)5106438);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[0] walkingSteps], 100);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[0] runningSteps], 200);

    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[1] date].minute, (RLYActivityTrackingMinute)8388607);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[1] walkingSteps], 50);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[1] runningSteps], 150);

    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[2] date].minute, (RLYActivityTrackingMinute)5237510);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[2] walkingSteps], 234);
    XCTAssertEqual([(RLYActivityTrackingUpdate*)events[2] runningSteps], 134);
}

@end
