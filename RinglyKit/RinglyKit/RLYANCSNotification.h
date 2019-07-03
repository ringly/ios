#import "RLYANCSNotificationFlags.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Enumerates the possible categories for an ANCS notification. Note that values from 12-255 are "reserved", so they may
 *  appear.
 *
 *  See [Apple's documentation](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/AppleNotificationCenterServiceSpecification/Appendix/Appendix.html#//apple_ref/doc/uid/TP40013460-CH3-SW1)
 *  for details.
 */
typedef NS_ENUM(uint8_t, RLYANCSCategory)
{
    /**
     *  Other.
     */
    RLYANCSCategoryOther = 0,
    
    /**
     *  An incoming call.
     */
    RLYANCSCategoryIncomingCall = 1,
    
    /**
     *  A missed call.
     */
    RLYANCSCategoryMissedCall = 2,
    
    /**
     *  A voicemail.
     */
    RLYANCSCategoryVoicemail = 3,
    
    /**
     *  Social.
     */
    RLYANCSCategorySocial = 4,
    
    /**
     *  Schedule.
     */
    RLYANCSCategorySchedule = 5,
    
    /**
     *  Email.
     */
    RLYANCSCategoryEmail = 6,
    
    /**
     *  News.
     */
    RLYANCSCategoryNews = 7,
    
    /**
     *  Health and fitness.
     */
    RLYANCSCategoryHealthAndFitness = 8,
    
    /**
     *  Business and finance.
     */
    RLYANCSCategoryBusinessAndFinance = 9,
    
    /**
     *  Location.
     */
    RLYANCSCategoryLocation = 10,
    
    /**
     *  Entertainment.
     */
    RLYANCSCategoryEntertainment = 11
};

/**
 *  Returns the `RLYANCSCategory` associated with the given numerical string (i.e. `@"1"`, `@"7"`).
 *
 *  Invalid values will return `RLYANCSCategoryOther`.
 *
 *  @param numericalString A numerical string.
 */
RINGLYKIT_EXTERN RLYANCSCategory RLYANCSCategoryFromNumericalString(NSString *numericalString);

/**
 *  Enumerates ANCS notification versions.
 */
typedef NS_ENUM(NSInteger, RLYANCSNotificationVersion)
{
    /**
     *  ANCS version 1.
     */
    RLYANCSNotificationVersion1,
    
    /**
     *  ANCS version 2.
     */
    RLYANCSNotificationVersion2
};

/**
 *  Represents an ANCS notification, transmitted to us by the Ringly peripheral.
 */
RINGLYKIT_FINAL @interface RLYANCSNotification : NSObject

#pragma mark - Initialization

/**
 *  `+new` is unavailable, use the designated initializer instead.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `-init` is unavailable, use the designated initializer instead.
 */
-(instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes an ANCS notification.
 *
 *  @param version               The version of the notification.
 *  @param category              The app category of the notification.
 *  @param applicationIdentifier The app's identifier (reverse DNS, typically).
 *  @param title                 The notification title. For SMS notifications and phone calls, this is the name of the
 *                               contact.
 *  @param date                  The date of the notification, as reported by ANCS.
 *  @param message               The notification message.
 *  @param flagsValue            The ANCS flags value. This will only be included on version 1 peripherals, with
 *                               application firmware versions greater than `1.4.3`.
 */
-(instancetype)initWithVersion:(RLYANCSNotificationVersion)version
                      category:(RLYANCSCategory)category
         applicationIdentifier:(NSString*)applicationIdentifier
                         title:(NSString*)title
                          date:(nullable NSDate*)date
                       message:(nullable NSString*)message
                    flagsValue:(nullable RLYANCSNotificationFlagsValue*)flagsValue NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The version of the notification.
 */
@property (nonatomic, readonly) RLYANCSNotificationVersion version;

/**
 *  The app category of the notification.
 */
@property (nonatomic, readonly) RLYANCSCategory category;

/**
 *  The app's identifier (reverse DNS, typically).
 */
@property (nonatomic, readonly, strong) NSString *applicationIdentifier;

/**
 *  The notification title. For SMS notifications and phone calls, this is the name of the contact.
 */
@property (nonatomic, readonly, strong) NSString *title;

/**
 *  The date of the notification, as reported by ANCS.
 */
@property (nullable, nonatomic, readonly, strong) NSDate *date;

/**
 *  The date of the notification, as reported by ANCS.
 */
@property (nullable, nonatomic, readonly, strong) NSString *message;

/**
 *  The ANCS flags value. This will only be included on version 1 peripherals, with application firmware versions
 *  greater than `1.4.3`.
 */
@property (nullable, nonatomic, readonly, strong) RLYANCSNotificationFlagsValue *flagsValue;

@end

NS_ASSUME_NONNULL_END
