#import "RLYErrorFunctions.h"
#import "RLYPeripheralActivityCharacteristics.h"
#import "RLYUUID.h"

@implementation RLYPeripheralActivityCharacteristics

+(nullable instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic *> *)characteristics
                                                               error:(NSError * _Nullable __autoreleasing *)error
{
    NSDictionary *dictionary = RLYMapCharacteristicsToUUIDs(characteristics);

    // find characteristics
    CBCharacteristic *controlPoint = dictionary[[RLYUUID activityServiceControlPointCharacteristic]];

    if (!controlPoint)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeActivityControlPointCharacteristicNotFound);
        return nil;
    }

    CBCharacteristic *trackingData = dictionary[[RLYUUID activityServiceTrackingDataCharacteristic]];

    if (!trackingData)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeActivityTrackingDataCharacteristicNotFound);
        return nil;
    }

    // create characteristics object
    RLYPeripheralActivityCharacteristics *activityCharacteristics = [[self alloc] init];

    if (activityCharacteristics)
    {
        activityCharacteristics->_controlPoint = controlPoint;
        activityCharacteristics->_trackingData = trackingData;
    }

    return activityCharacteristics;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(Activity characteristics: control point: %@, tracking data: %@)",
            _controlPoint, _trackingData];
}

@end
