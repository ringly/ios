#import "Ringly-Swift.h"
#import "RLog.h"

RLogType RLogIgnoredTypes = 0;

NSString *__nonnull RLogTypeToString(RLogType type)
{
    switch (type)
    {
        case RLogTypeANCS:
            return @"ANCS";
        case RLogTypeBluetooth:
            return @"Bluetooth";
        case RLogTypeDFU:
            return @"DFU";
        case RLogTypeDFUNordic:
            return @"DFUNordic";
        case RLogTypeGeneric:
            return @"Generic";
        case RLogTypeContacts:
            return @"Contacts";
        case RLogTypeNotifications:
            return @"Notifications";
        case RLogTypeUI:
            return @"UI";
        case RLogTypeAnalytics:
            return @"Analytics";
        case RLogTypeAB:
            return @"A/B Testing";
        case RLogTypeHolidays:
            return @"Holidays";
        case RLogTypeAPI:
            return @"API";
        case RLogTypeActivityTracking:
            return @"Activity Tracking";
        case RLogTypeActivityTrackingError:
            return @"Activity Tracking Error";
        case RLogTypeAppleNotifications:
            return @"Apple Notifications";
    }
}

void SLog(RLogType type, NSString *string)
{
    RLog(type, @"%@", string);
}

void RLog(RLogType type, NSString * __nonnull format, ...)
{
    va_list args;
    va_start(args, format);
    RLogv(type, format, args);
    va_end(args);
}

void RLogv(RLogType type, NSString * __nonnull format, va_list args)
{
    if ((type & RLogIgnoredTypes) == 0)
    {
        NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
        [[LoggingService sharedLoggingService] log:string type:type];
    }
}
