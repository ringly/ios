#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kDFUErrorDomain;

typedef NS_ENUM(NSInteger, DFUErrorCode)
{
    // packages
    DFUErrorCodeNoZipFile,
    DFUErrorCodeFailedToCreateDirectory,
    DFUErrorCodeMissingDataFile,
    
    // dfu process
    DFUErrorCodeNoApplication,
    DFUErrorCodeNoUpdate,
    DFUErrorCodeNoManager,
    DFUErrorCodeOnlyPrepareOnce,
    DFUErrorCodeOnlyWriteOnce,
    DFUErrorCodeNordic,
    DFUErrorCodeDisconnected,
    DFUErrorCodeNoRecoveryPeripheral,
    DFUErrorCodeNoWriteService,
    DFUErrorCodeNoWriteCharacteristic,
    DFUErrorCodeActually26,
    DFUErrorCodeCentralManagerPoweredOff,
    DFUErrorCodeCentralManagerUnsupported,
    DFUErrorCodeCentralManagerUnauthorized,
    DFUErrorCodeNotValidFileType,
    DFUErrorCodeCancelledByInterface,
    
    // dfu process v2
    DFUErrorCodeFailedToFindPeripheral,
    DFUErrorCodeUnknownApplicationVersion,
    DFUErrorCodeUnknownBootloaderVersion,
    DFUErrorCodeUnknownHardwareVersion,
    DFUErrorCodeRepeatingWriteTimeout,
    DFUErrorCodeScanningTimeout
};

FOUNDATION_EXTERN NSError *DFUMakeError(DFUErrorCode code);
FOUNDATION_EXTERN NSError *DFUMakeErrorWithReason(DFUErrorCode code, NSString *__nullable failureReason);

NS_ASSUME_NONNULL_END
