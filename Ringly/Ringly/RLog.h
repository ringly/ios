#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, RLogType)
{
    RLogTypeGeneric               = 1 << 0,
    RLogTypeBluetooth             = 1 << 1,
    RLogTypeANCS                  = 1 << 2,
    RLogTypeDFU                   = 1 << 3,
    RLogTypeContacts              = 1 << 4,
    RLogTypeNotifications         = 1 << 5,
    RLogTypeUI                    = 1 << 6,
    RLogTypeAnalytics             = 1 << 7,
    RLogTypeDFUNordic             = 1 << 8,
    RLogTypeAB                    = 1 << 9,
    RLogTypeHolidays              = 1 << 10,
    RLogTypeAPI                   = 1 << 11,
    RLogTypeActivityTracking      = 1 << 12,
    RLogTypeActivityTrackingError = 1 << 13,
    RLogTypeAppleNotifications    = 1 << 14
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *RLogTypeToString(RLogType type);

FOUNDATION_EXTERN void SLog(RLogType type, NSString *string);
FOUNDATION_EXTERN void RLog(RLogType type, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);
FOUNDATION_EXTERN void RLogv(RLogType type, NSString *format, va_list args);

FOUNDATION_EXTERN RLogType RLogIgnoredTypes;

#define LOG_FUNCTION(suffix) \
static inline void RLog##suffix(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);\
static inline void RLog##suffix(NSString *format, ...)\
{\
    va_list args;\
    va_start(args, format);\
    RLogv(RLogType##suffix, format, args);\
    va_end(args);\
}\
static inline void SLog##suffix(NSString *string)\
{\
    SLog(RLogType##suffix, string);\
}

LOG_FUNCTION(Generic)
LOG_FUNCTION(Bluetooth)
LOG_FUNCTION(ANCS)
LOG_FUNCTION(DFU)
LOG_FUNCTION(Contacts)
LOG_FUNCTION(Notifications)
LOG_FUNCTION(UI)
LOG_FUNCTION(Analytics)
LOG_FUNCTION(DFUNordic)
LOG_FUNCTION(AB)
LOG_FUNCTION(Holidays)
LOG_FUNCTION(API)
LOG_FUNCTION(ActivityTracking)
LOG_FUNCTION(ActivityTrackingError)
LOG_FUNCTION(AppleNotifications)

#undef LOG_FUNCTION

static inline void RLogEnumerateTypes(void(^block)(RLogType type))
{
    block(RLogTypeAB);
    block(RLogTypeANCS);
    block(RLogTypeAPI);
    block(RLogTypeActivityTracking);
    block(RLogTypeActivityTrackingError);
    block(RLogTypeAnalytics);
    block(RLogTypeAppleNotifications);
    block(RLogTypeBluetooth);
    block(RLogTypeContacts);
    block(RLogTypeDFU);
    block(RLogTypeDFUNordic);
    block(RLogTypeGeneric);
    block(RLogTypeHolidays);
    block(RLogTypeNotifications);
    block(RLogTypeUI);
}

NS_ASSUME_NONNULL_END
