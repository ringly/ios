#import <RinglyKit/RLYFunctions.h>
#import <XCTest/XCTest.h>

@interface RLYFunctionsTests : XCTestCase

@end

@implementation RLYFunctionsTests

-(void)testSupportsNotifyOrIndicate
{
    XCTAssertTrue(RLYSupportsNotifyOrIndicate(CBCharacteristicPropertyNotify));
    XCTAssertTrue(RLYSupportsNotifyOrIndicate(CBCharacteristicPropertyIndicate));
    
    XCTAssertTrue(RLYSupportsNotifyOrIndicate(CBCharacteristicPropertyIndicate |
                                              CBCharacteristicPropertyNotify));
    
    XCTAssertTrue(RLYSupportsNotifyOrIndicate(CBCharacteristicPropertyIndicate |
                                              CBCharacteristicPropertyRead));
    
    XCTAssertFalse(RLYSupportsNotifyOrIndicate(CBCharacteristicPropertyRead));
    XCTAssertFalse(RLYSupportsNotifyOrIndicate(0));
}

-(void)testRequiresEncryptionForNotifyOrIndicate
{
    XCTAssertTrue(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyNotifyEncryptionRequired));
    XCTAssertTrue(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyIndicateEncryptionRequired));
    XCTAssertTrue(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyNotifyEncryptionRequired |
                                                           CBCharacteristicPropertyIndicateEncryptionRequired));

    XCTAssertTrue(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyNotifyEncryptionRequired |
                                                           CBCharacteristicPropertyRead |
                                                           CBCharacteristicPropertyNotify));

    XCTAssertFalse(RLYRequiresEncryptionForNotifyOrIndicate(0));
    XCTAssertFalse(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyRead));
    XCTAssertFalse(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyIndicate));
    XCTAssertFalse(RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicPropertyNotify));
}

-(void)testDataForFlashLogAll0
{
    uint8_t expected[8] = { 0, 9, 0, 0, 0, 0, 0, 0 };

    XCTAssertEqualObjects(
        RLYDataForReadingFlashLog(0, 0),
        [NSData dataWithBytes:expected length:sizeof(expected)]
    );
}

-(void)testDataForFlashLogMixed
{
    uint8_t expected[8] = { 0, 9, 89, 47, 217, 32, 111, 126 };

    XCTAssertEqualObjects(
        RLYDataForReadingFlashLog(12121, 2121212121),
        [NSData dataWithBytes:expected length:sizeof(expected)]
    );
}

-(void)testDataForFlashLogAllMax
{
    uint8_t expected[8] = { 0, 9, 255, 255, 255, 255, 255, 255 };

    XCTAssertEqualObjects(
        RLYDataForReadingFlashLog(UINT16_MAX, UINT32_MAX),
        [NSData dataWithBytes:expected length:sizeof(expected)]
    );
}

@end
