#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYPeripheralBatteryCharacteristics.h>
#import <RinglyKit/RLYPeripheralDeviceInformationCharacteristics.h>
#import <RinglyKit/RLYPeripheralLoggingCharacteristics.h>
#import <RinglyKit/RLYPeripheralRinglyCharacteristics.h>
#import <RinglyKit/RLYUUID.h>
#import <XCTest/XCTest.h>

@interface MockCharacteristic : NSObject

@property (nonatomic, strong) CBUUID *UUID;

@end

@implementation MockCharacteristic

-(instancetype)initWithUUID:(CBUUID*)UUID
{
    self = [super init];
    
    if (self)
    {
        _UUID = UUID;
    }
    
    return self;
}

@end

static inline NSDictionary* RemoveFromDictionary(NSDictionary *dictionary, id key)
{
    NSMutableDictionary *copy = [dictionary mutableCopy];
    [copy removeObjectForKey:key];
    return copy;
}

#pragma mark -

@interface RLYPeripheralRinglyCharacteristicsTests : XCTestCase

@property (nonatomic, strong) NSMutableDictionary *mockCharacteristics;

@end

@implementation RLYPeripheralRinglyCharacteristicsTests

-(void)setUp
{
    [super setUp];
    
    self.mockCharacteristics = @{
       [RLYUUID writeCharacteristicLong]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID writeCharacteristicLong]],
       [RLYUUID messageCharacteristicLong]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID messageCharacteristicLong]],
       [RLYUUID ANCSVersion2Characteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID ANCSVersion2Characteristic]],
       [RLYUUID bondCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID bondCharacteristic]],
       [RLYUUID ANCSVersion1CharacteristicLong]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID ANCSVersion1CharacteristicLong]],
       [RLYUUID clearBondCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID clearBondCharacteristic]],
       [RLYUUID configurationHashCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID configurationHashCharacteristic]]
    }.mutableCopy;
}

-(void)testANCSVersion1
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID ANCSVersion2Characteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNotNil(result.ANCSVersion1);
    XCTAssertNil(result.ANCSVersion2);
}

-(void)testANCSVersion2
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID ANCSVersion1CharacteristicLong]).allValues;
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNil(result.ANCSVersion1);
    XCTAssertNotNil(result.ANCSVersion2);
}

-(void)testMissingAnyANCSCharacteristic
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion1CharacteristicLong]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion2Characteristic]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeANCSNotificationCharacteristicNotFound);
}

-(void)testBothANCSCharacteristics
{
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeTooManyANCSNotificationCharacteristicsFound);
}

-(void)testMissingCommandCharacteristic
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion2Characteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID writeCharacteristicLong]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeCommandCharacteristicNotFound);
}

-(void)testMissingMessageCharacteristic
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion2Characteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID messageCharacteristicLong]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeMessageCharacteristicNotFound);
}

-(void)testMissingBondCharacteristicANCSVersion1
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID bondCharacteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion2Characteristic]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNil(result.bond);
}

-(void)testMissingBondCharacteristicANCSVersion2
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID bondCharacteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion1CharacteristicLong]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeBondCharacteristicNotFound);
}

-(void)testMissingClearBondCharacteristicANCSVersion1
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID clearBondCharacteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion2Characteristic]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNil(result.clearBond);
}

-(void)testMissingClearBondCharacteristicANCSVersion2
{
    [_mockCharacteristics removeObjectForKey:[RLYUUID clearBondCharacteristic]];
    [_mockCharacteristics removeObjectForKey:[RLYUUID ANCSVersion1CharacteristicLong]];
    
    NSError *error = nil;
    RLYPeripheralRinglyCharacteristics *result =
        [RLYPeripheralRinglyCharacteristics peripheralCharacteristicsWithCharacteristics:_mockCharacteristics.allValues
                                                                                   error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeClearBondCharacteristicNotFound);
}

@end

#pragma mark -

@interface RLYPeripheralDeviceInformationCharacteristicsTests : XCTestCase

@end

@implementation RLYPeripheralDeviceInformationCharacteristicsTests

-(NSDictionary*)mockCharacteristics
{
    return @{
       [RLYUUID MACAddressCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID MACAddressCharacteristic]],
       [RLYUUID applicationVersionCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID applicationVersionCharacteristic]],
       [RLYUUID softdeviceVersionCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID softdeviceVersionCharacteristic]],
       [RLYUUID bootloaderVersionCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID bootloaderVersionCharacteristic]],
       [RLYUUID hardwareVersionCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID hardwareVersionCharacteristic]],
       [RLYUUID chipVersionCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID chipVersionCharacteristic]],
       [RLYUUID manufacturerCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID manufacturerCharacteristic]]
    };
}

-(void)testAllCharacteristicsPresent
{
    NSArray *chars = [self mockCharacteristics].allValues;
    
    NSError *error = nil;
    id result = [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNotNil([result softdevice]);
    XCTAssertNotNil([result chip]);
    XCTAssertNotNil([result bootloader]);
}

-(void)testMissingMACAddress
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID MACAddressCharacteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralDeviceInformationCharacteristics *result =
        [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];

    XCTAssertNotNil(result);
    XCTAssertNil([result MACAddress]);
    XCTAssertNil(error);
}

-(void)testMissingApplicationVersion
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID applicationVersionCharacteristic]).allValues;
    
    NSError *error = nil;
    id result = [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeDeviceApplicationCharacteristicNotFound);
}

-(void)testMissingHardwareVersion
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID hardwareVersionCharacteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralDeviceInformationCharacteristics *result =
        [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];

    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeDeviceHardwareCharacteristicNotFound);
}

-(void)testMissingManufacturer
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID manufacturerCharacteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralDeviceInformationCharacteristics *result =
        [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];

    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeDeviceManufacturerCharacteristicNotFound);
}

-(void)testMissingSoftdevice
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID softdeviceVersionCharacteristic]).allValues;
    
    NSError *error = nil;
    id result = [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNil([result softdevice]);
    XCTAssertNotNil([result chip]);
    XCTAssertNotNil([result bootloader]);
}

-(void)testMissingBootloader
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID bootloaderVersionCharacteristic]).allValues;
    
    NSError *error = nil;
    id result = [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNotNil([result softdevice]);
    XCTAssertNotNil([result chip]);
    XCTAssertNil([result bootloader]);
}

-(void)testMissingChip
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID chipVersionCharacteristic]).allValues;
    
    NSError *error = nil;
    id result = [RLYPeripheralDeviceInformationCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNotNil([result softdevice]);
    XCTAssertNil([result chip]);
    XCTAssertNotNil([result bootloader]);
}

@end

@interface RLYPeripheralBatteryCharacteristicsTests : XCTestCase

@end

@implementation RLYPeripheralBatteryCharacteristicsTests

-(NSDictionary*)mockCharacteristics
{
    return @{
       [RLYUUID batteryLevelCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID batteryLevelCharacteristic]],
       [RLYUUID chargeStateCharacteristic]: [[MockCharacteristic alloc] initWithUUID:[RLYUUID chargeStateCharacteristic]]
    };
}

-(void)testAllCharacteristicsPresent
{
    NSArray *chars = [self mockCharacteristics].allValues;
    
    NSError *error = nil;
    RLYPeripheralBatteryCharacteristics* result =
        [RLYPeripheralBatteryCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertNotNil(result.charge);
    XCTAssertNotNil(result.state);
}

-(void)testMissingCharge
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID batteryLevelCharacteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralBatteryCharacteristics* result =
        [RLYPeripheralBatteryCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeBatteryChargeCharacteristicNotFound);
}

-(void)testMissingState
{
    NSArray *chars = RemoveFromDictionary([self mockCharacteristics], [RLYUUID chargeStateCharacteristic]).allValues;
    
    NSError *error = nil;
    RLYPeripheralBatteryCharacteristics* result =
        [RLYPeripheralBatteryCharacteristics peripheralCharacteristicsWithCharacteristics:chars error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, RLYPeripheralErrorDomain);
    XCTAssertEqual(error.code, RLYPeripheralErrorCodeBatteryStateCharacteristicNotFound);
}

@end
