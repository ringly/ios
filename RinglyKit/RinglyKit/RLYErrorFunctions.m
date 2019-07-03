#import "RLYErrorFunctions.h"

#pragma mark - ANCS v1
NSString *const RLYANCSV1ErrorDomain = @"com.ringly.RinglyKit.ANCSV1";

static NSString *RLYANCSV1ErrorFailureReason(RLYANCSV1ErrorCode code)
{
    switch (code)
    {
        case RLYANCSV1ErrorCodeDifferentHeader:
            return @"Different hader";
            
        case RLYANCSV1ErrorCodeInvalidHeader:
            return @"Invalid header";
    }
}

NSError *RLYANCSV1Error(RLYANCSV1ErrorCode code)
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"ANCS v1 Error",
                                NSLocalizedFailureReasonErrorKey: RLYANCSV1ErrorFailureReason(code) };
    
    return [NSError errorWithDomain:RLYANCSV1ErrorDomain code:code userInfo:userInfo];
}

#pragma mark - ANCS v2
NSString *const RLYANCSV2ErrorDomain = @"com.ringly.RinglyKit.ANCSV2";

static NSString *RLYANCSV2ErrorFailureReason(RLYANCSV2ErrorCode code)
{
    switch (code)
    {
        case RLYANCSV2ErrorCodeIncorrectDataSize:
            return @"Incorrect data size";
            
        case RLYANCSV2ErrorCodeInvalidNotificationAttributesCommandIdentifier:
            return @"Invalid notification attributes command identifier";
            
        case RLYANCSV2ErrorCodeInvalidApplicationAttributesCommandIdentifier:
            return @"Invalid application attributes command identifier";
            
        case RLYANCSV2ErrorCodeMissingTitle:
            return @"Missing title";
            
        case RLYANCSV2ErrorCodeMissingDate:
            return @"Missing date";
    }
}

NSError *RLYANCSV2Error(RLYANCSV2ErrorCode code, NSData *data)
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"ANCS v2 Error",
                                NSLocalizedFailureReasonErrorKey: RLYANCSV2ErrorFailureReason(code),
                                RLYANCSV2DataErrorKey: [data description] };
    
    return [NSError errorWithDomain:RLYANCSV2ErrorDomain code:code userInfo:userInfo];
}

#pragma mark - Activity Tracking Data Errors
NSString *const RLYActivityTrackingUpdateErrorDomain = @"com.ringly.RinglyKit.ActivityTrackingUpdate";
NSString *const RLYActivityTrackingUpdateInvalidDataErrorKey = @"Invalid Data";

static NSString *RLYActivityTrackingUpdateFailureReason(RLYActivityTrackingUpdateErrorCode code)
{
    switch (code)
    {
        case RLYActivityTrackingUpdateErrorCodeIncorrectDataLength:
            return @"Incorrect data length";
        case RLYActivityTrackingUpdateErrorCodeDateError:
            return @"Date error";
    }
}

NSError *RLYActivityTrackingUpdateError(RLYActivityTrackingUpdateErrorCode code, NSDictionary *userInfo)
{
    NSMutableDictionary *mutable = [userInfo mutableCopy] ?: [NSMutableDictionary dictionaryWithCapacity:2];
    mutable[NSLocalizedDescriptionKey] = @"Activity Tracking Update Error";
    mutable[NSLocalizedFailureReasonErrorKey] = RLYActivityTrackingUpdateFailureReason(code);

    return [NSError errorWithDomain:RLYActivityTrackingUpdateErrorDomain code:code userInfo:mutable];
}

#pragma mark - Activity Tracking Date Errors
NSString *const RLYActivityTrackingDateErrorDomain = @"com.ringly.RinglyKit.ActivityTrackingDate";
NSString *const RLYActivityTrackingDateInvalidIntervalKey = @"Invalid Interval";
NSString *const RLYActivityTrackingDateInvalidTimestampKey = @"Invalid Timestamp";

static NSString *RLYActivityTrackingDateFailureReason(RLYActivityTrackingDateErrorCode code)
{
    switch (code)
    {
        case RLYActivityTrackingDateErrorCodeIntervalLessThanMinimum:
            return @"Interval was less than minimum allowed value";

        case RLYActivityTrackingDateErrorCodeIntervalGreaterThanMaximum:
            return @"Interval was greater than maximum allowed value";
    }
}

NSError *RLYActivityTrackingDateError(RLYActivityTrackingDateErrorCode code, NSDictionary *userInfo)
{
    NSMutableDictionary *mutable = [userInfo mutableCopy] ?: [NSMutableDictionary dictionaryWithCapacity:2];
    mutable[NSLocalizedDescriptionKey] = @"Activity Tracking Date Error";
    mutable[NSLocalizedFailureReasonErrorKey] = RLYActivityTrackingDateFailureReason(code);

    return [NSError errorWithDomain:RLYActivityTrackingDateErrorDomain code:code userInfo:mutable];
}

#pragma mark - Peripheral
NSString *const RLYPeripheralErrorDomain = @"com.ringly.RinglyKit.Peripheral";

static NSString *RLYPeripheralErrorFailureReason(RLYPeripheralErrorCode code)
{
    switch (code)
    {
        case RLYPeripheralErrorCodePeripheralDisconnected:
            return @"The peripheral disconnected";
            
        case RLYPeripheralErrorCodeDeviceApplicationCharacteristicNotFound:
            return @"Device firmware characteristic not found";
            
        case RLYPeripheralErrorCodeDeviceHardwareCharacteristicNotFound:
            return @"Device hardware characteristic not found";
            
        case RLYPeripheralErrorCodeBondCharacteristicNotFound:
            return @"Bond characteristic not found";
            
        case RLYPeripheralErrorCodeClearBondCharacteristicNotFound:
            return @"Clear bond characteristic not found";
            
        case RLYPeripheralErrorCodeBatteryStateCharacteristicNotFound:
            return @"Battery state characteristic not found";
            
        case RLYPeripheralErrorCodeBatteryChargeCharacteristicNotFound:
            return @"Battery charge characteristic not found";
            
        case RLYPeripheralErrorCodeNoServicesFound:
            return @"No services found";
            
        case RLYPeripheralErrorCodeRinglyServiceNotFound:
            return @"Ringly service not found";
            
        case RLYPeripheralErrorCodeBatteryServiceNotFound:
            return @"Battery service not found";
            
        case RLYPeripheralErrorCodeDeviceInformationServiceNotFound:
            return @"Device Information service not found";
            
        case RLYPeripheralErrorCodeANCSNotificationCharacteristicNotFound:
            return @"ANCS notification characteristic not found";
            
        case RLYPeripheralErrorCodeTooManyANCSNotificationCharacteristicsFound:
            return @"Too many ANCS notification characteristics found";
            
        case RLYPeripheralErrorCodeMessageCharacteristicNotFound:
            return @"Message characteristic not found";
            
        case RLYPeripheralErrorCodeCommandCharacteristicNotFound:
            return @"Command characteristic not found";
            
        case RLYPeripheralErrorCodeDeviceManufacturerCharacteristicNotFound:
            return @"Device manufacturer characteristic not found";
            
        case RLYPeripheralErrorCodeConfigurationHashCharacteristicNotFound:
            return @"Configuration hash characteristic not found";

        case RLYPeripheralErrorCodeActivityControlPointCharacteristicNotFound:
            return @"Activity control point characteristic not found";

        case RLYPeripheralErrorCodeActivityTrackingDataCharacteristicNotFound:
            return @"Activity tracking data characteristic not found";
            
        case RLYPeripheralErrorCodeIncorrectLength:
            return @"Incorrect length";

        case RLYPeripheralErrorCodeNotSubscribedToActivityNotifications:
            return @"Not subscribed to activity notifications";

        case RLYPeripheralErrorCodeLoggingServiceNotFound:
            return @"Logging service not found";

        case RLYPeripheralErrorCodeLoggingFlashCharacteristicNotFound:
            return @"Flash characteristic not found";

        case RLYPeripheralErrorCodeLoggingRequestCharacteristicNotFound:
            return @"Request characteristic not found";
    }
}

NSError *RLYPeripheralError(RLYPeripheralErrorCode code)
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Peripheral Error",
                                NSLocalizedFailureReasonErrorKey: RLYPeripheralErrorFailureReason(code) };
    
    return [NSError errorWithDomain:RLYPeripheralErrorDomain code:code userInfo:userInfo];
}

NSString *const RLYANCSV2DataErrorKey = @"ANCSV2Data";
