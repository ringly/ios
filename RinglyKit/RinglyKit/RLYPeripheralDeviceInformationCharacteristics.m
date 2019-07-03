#import "RLYErrorFunctions.h"
#import "RLYPeripheralDeviceInformationCharacteristics.h"
#import "RLYUUID.h"

@implementation RLYPeripheralDeviceInformationCharacteristics

+(instancetype)peripheralCharacteristicsWithCharacteristics:(NSArray<CBCharacteristic*>*)characteristics
                                                      error:(NSError * _Nullable __autoreleasing *)error
{
    // find characteristics
    NSDictionary *dictionary = RLYMapCharacteristicsToUUIDs(characteristics);
    
    CBCharacteristic *application = dictionary[[RLYUUID applicationVersionCharacteristic]];
        
    if (!application)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceApplicationCharacteristicNotFound);
        return nil;
    }
    
    CBCharacteristic *hardware = dictionary[[RLYUUID hardwareVersionCharacteristic]];
    
    if (!hardware)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceHardwareCharacteristicNotFound);
        return nil;
    }
    
    CBCharacteristic *manufacturer = dictionary[[RLYUUID manufacturerCharacteristic]];
    
    if (!manufacturer)
    {
        if (error) *error = RLYPeripheralError(RLYPeripheralErrorCodeDeviceManufacturerCharacteristicNotFound);
        return nil;
    }
    
    CBCharacteristic *bootloader = dictionary[[RLYUUID bootloaderVersionCharacteristic]];
    CBCharacteristic *chip = dictionary[[RLYUUID chipVersionCharacteristic]];
    CBCharacteristic *softdevice = dictionary[[RLYUUID softdeviceVersionCharacteristic]];
    CBCharacteristic *MACAddress = dictionary[[RLYUUID MACAddressCharacteristic]];
    
    // create object, map characteristics to properties
    RLYPeripheralDeviceInformationCharacteristics *peripheralCharacteristics = [self new];
    
    if (peripheralCharacteristics)
    {
        peripheralCharacteristics->_MACAddress = MACAddress;
        peripheralCharacteristics->_application = application;
        peripheralCharacteristics->_hardware = hardware;
        peripheralCharacteristics->_manufacturer = manufacturer;
        peripheralCharacteristics->_bootloader = bootloader;
        peripheralCharacteristics->_chip = chip;
        peripheralCharacteristics->_softdevice = softdevice;
    }
    
    return peripheralCharacteristics;
}

-(NSString*)description
{
    return [NSString stringWithFormat:
            @"(Device information characteristics: MAC: %@, application: %@, bootloader: %@, softdevice: %@, hardware: %@, chip: %@, manufacturer: %@)",
            _MACAddress, _application, _bootloader, _softdevice, _hardware, _chip, _manufacturer];
}

@end
