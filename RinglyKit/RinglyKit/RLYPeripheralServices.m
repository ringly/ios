#import "RLYErrorFunctions.h"
#import "RLYPeripheralServices.h"
#import "RLYUUID.h"

static NSDictionary *RLYMapServicesToUUIDs(NSArray *services)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:services.count];
    
    for (CBService *service in services)
    {
        dictionary[service.UUID] = service;
    }
    
    return dictionary;
}

@implementation RLYPeripheralServices

+(instancetype)peripheralServicesWithServices:(NSArray<CBService *> *)services error:(NSError * _Nullable __autoreleasing *)error
{
    NSDictionary *dictionary = RLYMapServicesToUUIDs(services);
    
    // find ringly-specific services
    CBService *ringlyService = dictionary[[RLYUUID ringlyServiceShort]] ?: dictionary[[RLYUUID ringlyServiceLong]];
    
    if (!ringlyService)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeRinglyServiceNotFound);
        return nil;
    }
    
    CBService *loggingService = dictionary[[RLYUUID loggingServiceShort]] ?: dictionary[[RLYUUID loggingServiceLong]];
    CBService *activityService = dictionary[[RLYUUID activityService]];
    
    // find standard services
    CBService *batteryService = dictionary[[RLYUUID batteryService]];
    
    if (!batteryService)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeBatteryServiceNotFound);
        return nil;
    }
    
    CBService *deviceInformationService = dictionary[[RLYUUID deviceInformationService]];
    
    if (!deviceInformationService)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceInformationServiceNotFound);
        return nil;
    }
    
    RLYPeripheralServices *peripheralServices = [self new];
    
    if (peripheralServices)
    {
        peripheralServices->_ringlyService = ringlyService;
        peripheralServices->_loggingService = loggingService;
        peripheralServices->_activityService = activityService;
        peripheralServices->_batteryService = batteryService;
        peripheralServices->_deviceInformationService = deviceInformationService;
    }
    
    return peripheralServices;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"(Services: ringly: %@, battery: %@, device information: %@, logging: %@, activity: %@)",
            _ringlyService, _batteryService, _deviceInformationService, _loggingService, _activityService];
}

@end
