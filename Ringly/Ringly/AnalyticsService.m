#import <Mixpanel/Mixpanel.h>
#import "Ringly-Swift.h"
#import "AnalyticsService.h"

// mixpanel
NSString *const kAnalyticsMixpanelToken = @"YOUR-TOKEN-HERE";

// events
NSString *__nonnull const kAnalyticsTappedButton = @"Tapped Button";
NSString *__nonnull const kAnalyticsViewedScreen = @"Viewed Screen";
NSString *__nonnull const kAnalyticsDisabledNotification = @"Disabled Notification";
NSString *__nonnull const kAnalyticsDisabledContact = @"Disabled Contact";
NSString *__nonnull const kAnalyticsChangedSetting = @"Changed Setting";
NSString *__nonnull const kAnalyticsApplicationLaunched = @"Application Launch";
NSString *__nonnull const kAnalyticsApplicationForeground = @"Application Foreground";
NSString *__nonnull const kAnalyticsApplicationBackground = @"Application Background";
NSString *__nonnull const kAnalyticsShareServiceTapped = @"Share Service Tapped";
NSString *__nonnull const kAnalyticsShareRedeemTapped = @"Redeem Tapped";
NSString *__nonnull const kAnalyticsProfileEditShown = @"Profile Edit Shown";
NSString *__nonnull const kAnalyticsProfileSaved = @"Profile Saved";
NSString *__nonnull const kAnalyticsApplicationError = @"Application Error iOS";

NSString *const kAnalyticsNotificationsRequested = @"Notifications Requested";
NSString *const kAnalyticsNotificationsCompleted = @"Notifications Completed";

NSString *const kAnalyticsDFUBannerShown = @"DFU Banner Shown";
NSString *const kAnalyticsDFUTapped = @"DFU Tapped";
NSString *const kAnalyticsDFUCancelled = @"DFU Cancelled";
NSString *const kAnalyticsDFUDownloaded = @"DFU Downloaded";
NSString *const kAnalyticsDFUStart = @"DFU Start";
NSString *const kAnalyticsDFURequestedRingInCharger = @"DFU Requested Ring in Charger";
NSString *const kAnalyticsDFURingInCharger = @"DFU Ring in Charger";
NSString *const kAnalyticsDFURequestedPhoneCharging = @"DFU Requested Phone Charging";
NSString *const kAnalyticsDFUPhoneCharging = @"DFU Phone Charging";
NSString *const kAnalyticsDFURequestedForgetThisDevice = @"DFU Requested Forget This Device";
NSString *const kAnalyticsDFUForgetThisDevice = @"DFU Forget This Device";
NSString *const kAnalyticsDFURequestedToggleBluetooth = @"DFU Requested Toggle Bluetooth";;
NSString *const kAnalyticsDFUToggleBluetooth = @"DFU Toggle Bluetooth";
NSString *const kAnalyticsDFUWriteStarted = @"DFU Write Started";
NSString *const kAnalyticsDFUWriteCompleted = @"DFU Write Completed";
NSString *const kAnalyticsDFUCompleted = @"DFU Completed";

// properties
NSString *__nonnull const kAnalyticsPropertyScreen = @"Screen";
NSString *__nonnull const kAnalyticsPropertyName = @"Name";
NSString *__nonnull const kAnalyticsPropertyService = @"Service";
NSString *__nonnull const kAnalyticsPropertyDomain = @"Domain";
NSString *__nonnull const kAnalyticsPropertyCode = @"Code";
NSString *__nonnull const kAnalyticsPropertyAccepted = @"Accepted";
NSString *__nonnull const kAnalyticsPropertyPackageType = @"Package Type";
NSString *__nonnull const kAnalyticsPropertyIndex = @"Index";
NSString *__nonnull const kAnalyticsPropertyCount = @"Count";
NSString *__nonnull const kAnalyticsPropertyDFUVersion = @"DFU Version";
NSString *__nonnull const kAnalyticsPropertyPackageVersion = @"Package Version";

// values
NSString *__nonnull const kAnalyticsValueProfile = @"Profile";
NSString *__nonnull const kAnalyticsValueConnection = @"Connection";
NSString *__nonnull const kAnalyticsValueNotifications = @"Notifications";
NSString *__nonnull const kAnalyticsValueContacts = @"Contacts";
NSString *__nonnull const kAnalyticsValueShare = @"Share";
NSString *__nonnull const kAnalyticsValueHelp = @"Help";
NSString *__nonnull const kAnalyticsValueLegal = @"Legal";
NSString *__nonnull const kAnalyticsValueCantConnect = @"Can't Connect";
NSString *__nonnull const kAnalyticsValueFacebook = @"Facebook";
NSString *__nonnull const kAnalyticsValuePinterest = @"Pinterest";
NSString *__nonnull const kAnalyticsValueSMS = @"SMS";
NSString *__nonnull const kAnalyticsValueEmail = @"Email";
NSString *__nonnull const kAnalyticsValueSleepMode = @"Sleep Mode";
NSString *__nonnull const kAnalyticsValueInnerRing = @"Inner Ring";
NSString *__nonnull const kAnalyticsValueOutOfRange = @"Out of Range";
NSString *__nonnull const kAnalyticsValueConnectionTaps = @"Connection Taps";
NSString *__nonnull const kAnalyticsValueConnect = @"Connect";
NSString *__nonnull const kAnalyticsValueDisconnect = @"Disconnect";
NSString *__nonnull const kAnalyticsValueForgetThisRing = @"Forget this Ring";
