#import "DFUError.h"

NSString *const kDFUErrorDomain = @"com.ringly.Ringly.FirmwareUpdate";

NSString *DFUErrorFailureReason(DFUErrorCode code)
{
    switch (code)
    {
        case DFUErrorCodeNoApplication:
            return @"An application is required";
        case DFUErrorCodeNoManager:
            return @"Failed to download update";
        case DFUErrorCodeNoUpdate:
            return @"An update is required";
        case DFUErrorCodeFailedToCreateDirectory:
            return @"Failed to create directory";
        case DFUErrorCodeMissingDataFile:
            return @"Missing data file";
        case DFUErrorCodeNoZipFile:
            return @"Missing archive file";
        case DFUErrorCodeOnlyPrepareOnce:
            return @"Peripheral preparation already started";
        case DFUErrorCodeOnlyWriteOnce:
            return @"Writable already used";
        case DFUErrorCodeNordic:
            return @"Nordic Error"; // not actually used, custom error text provided
        case DFUErrorCodeDisconnected:
            return @"Device disconnected";
        case DFUErrorCodeNoRecoveryPeripheral:
            return @"No recovery device";
        case DFUErrorCodeNoWriteService:
            return @"No write service";
        case DFUErrorCodeNoWriteCharacteristic:
            return @"No write characteristic";
        case DFUErrorCodeActually26:
            return @"1.0 peripheral was actually 26";
        case DFUErrorCodeCentralManagerPoweredOff:
            return @"Bluetooth powered off";
        case DFUErrorCodeCentralManagerUnauthorized:
            return @"Bluetooth use unauthorized";
        case DFUErrorCodeCentralManagerUnsupported:
            return @"Bluetooth use unsupported";
        case DFUErrorCodeNotValidFileType:
            return @"Not a valid file type";
        case DFUErrorCodeCancelledByInterface:
            return @"";
            
        case DFUErrorCodeFailedToFindPeripheral:
            return @"Failed to find peripheral";
        case DFUErrorCodeUnknownApplicationVersion:
            return @"Unknown application version";
        case DFUErrorCodeUnknownBootloaderVersion:
            return @"Unknown bootloader version";
        case DFUErrorCodeUnknownHardwareVersion:
            return @"Unknown hardware version";
        case DFUErrorCodeRepeatingWriteTimeout:
        case DFUErrorCodeScanningTimeout:
            return @"Timed out";
    }
}

NSError *DFUMakeError(DFUErrorCode code)
{
    return DFUMakeErrorWithReason(code, DFUErrorFailureReason(code));
}

NSError *DFUMakeErrorWithReason(DFUErrorCode code, NSString *failureReason)
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[NSLocalizedDescriptionKey] = @"Update Failed";
    
    if (failureReason)
    {
        dictionary[NSLocalizedFailureReasonErrorKey] = failureReason;
    }
    
    return [NSError errorWithDomain:kDFUErrorDomain code:code userInfo:dictionary];
}
