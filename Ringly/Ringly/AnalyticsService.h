#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Mixpanel
FOUNDATION_EXTERN NSString *const kAnalyticsMixpanelToken;

#pragma mark - Events
FOUNDATION_EXTERN NSString *const kAnalyticsTappedButton;
FOUNDATION_EXTERN NSString *const kAnalyticsViewedScreen;
FOUNDATION_EXTERN NSString *const kAnalyticsDisabledNotification;
FOUNDATION_EXTERN NSString *const kAnalyticsDisabledContact;
FOUNDATION_EXTERN NSString *const kAnalyticsChangedSetting;
FOUNDATION_EXTERN NSString *const kAnalyticsApplicationLaunched;
FOUNDATION_EXTERN NSString *const kAnalyticsApplicationForeground;
FOUNDATION_EXTERN NSString *const kAnalyticsApplicationBackground;
FOUNDATION_EXTERN NSString *const kAnalyticsShareServiceTapped;
FOUNDATION_EXTERN NSString *const kAnalyticsShareRedeemTapped;
FOUNDATION_EXTERN NSString *const kAnalyticsProfileEditShown;
FOUNDATION_EXTERN NSString *const kAnalyticsProfileSaved;
FOUNDATION_EXTERN NSString *const kAnalyticsApplicationError;

FOUNDATION_EXTERN NSString *const kAnalyticsNotificationsRequested;
FOUNDATION_EXTERN NSString *const kAnalyticsNotificationsCompleted;

FOUNDATION_EXTERN NSString *const kAnalyticsDFUBannerShown;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUTapped;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUCancelled;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUDownloaded;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUStart;
FOUNDATION_EXTERN NSString *const kAnalyticsDFURequestedRingInCharger;
FOUNDATION_EXTERN NSString *const kAnalyticsDFURingInCharger;
FOUNDATION_EXTERN NSString *const kAnalyticsDFURequestedPhoneCharging;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUPhoneCharging;
FOUNDATION_EXTERN NSString *const kAnalyticsDFURequestedForgetThisDevice;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUForgetThisDevice;
FOUNDATION_EXTERN NSString *const kAnalyticsDFURequestedToggleBluetooth;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUToggleBluetooth;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUWriteStarted;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUWriteCompleted;
FOUNDATION_EXTERN NSString *const kAnalyticsDFUCompleted;

#pragma mark - Properties
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyScreen;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyName;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyService;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyDomain;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyCode;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyAccepted;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyPackageType;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyIndex;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyCount;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyDFUVersion;
FOUNDATION_EXTERN NSString *const kAnalyticsPropertyPackageVersion;

#pragma mark - Values
FOUNDATION_EXTERN NSString *const kAnalyticsValueProfile;
FOUNDATION_EXTERN NSString *const kAnalyticsValueConnection;
FOUNDATION_EXTERN NSString *const kAnalyticsValueNotifications;
FOUNDATION_EXTERN NSString *const kAnalyticsValueContacts;
FOUNDATION_EXTERN NSString *const kAnalyticsValueShare;
FOUNDATION_EXTERN NSString *const kAnalyticsValueHelp;
FOUNDATION_EXTERN NSString *const kAnalyticsValueLegal;
FOUNDATION_EXTERN NSString *const kAnalyticsValueCantConnect;
FOUNDATION_EXTERN NSString *const kAnalyticsValueFacebook;
FOUNDATION_EXTERN NSString *const kAnalyticsValuePinterest;
FOUNDATION_EXTERN NSString *const kAnalyticsValueSMS;
FOUNDATION_EXTERN NSString *const kAnalyticsValueEmail;
FOUNDATION_EXTERN NSString *const kAnalyticsValueSleepMode;
FOUNDATION_EXTERN NSString *const kAnalyticsValueInnerRing;
FOUNDATION_EXTERN NSString *const kAnalyticsValueOutOfRange;
FOUNDATION_EXTERN NSString *const kAnalyticsValueConnectionTaps;
FOUNDATION_EXTERN NSString *const kAnalyticsValueConnect;
FOUNDATION_EXTERN NSString *const kAnalyticsValueDisconnect;
FOUNDATION_EXTERN NSString *const kAnalyticsValueForgetThisRing;

NS_ASSUME_NONNULL_END
