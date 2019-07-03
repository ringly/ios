#import "RLYColor.h"
#import "RLYCommand.h"
#import "RLYSettingsCommandMode.h"
#import "RLYVibration.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Updates the notification settings for an application.
 */
RINGLYKIT_FINAL @interface RLYApplicationSettingsCommand : NSObject <RLYCommand>

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
*  Returns an application settings command with the specified application identifier.
*
*  @param mode                  Whether to add or delete the application setting.
*  @param applicationIdentifier The application identifier to add.
*  @param color                 The color to use for the application.
*  @param vibration             The vibration to use for the application.
*/
-(instancetype)initWithMode:(RLYSettingsCommandMode)mode
      applicationIdentifier:(NSString*)applicationIdentifier
                      color:(RLYColor)color
                  vibration:(RLYVibration)vibration NS_DESIGNATED_INITIALIZER;

#pragma mark - Creation

/**
 *  Returns an "add" command with the specified application identifier.
 *
 *  @param applicationIdentifier The application identifier to add.
 *  @param color                 The color to use for the application.
 *  @param vibration             The vibration to use for the application.
 */
+(instancetype)addCommandWithApplicationIdentifier:(NSString*)applicationIdentifier
                                             color:(RLYColor)color
                                         vibration:(RLYVibration)vibration;

/**
 *  Returns a "delete" command with the specified application identifier.
 *
 *  @param applicationIdentifier The application identifier to delete.
 */
+(instancetype)deleteCommandWithApplicationIdentifier:(NSString*)applicationIdentifier;

#pragma mark - Application Identifier

/**
 *  The application identifier for this command.
 */
@property (nonatomic, readonly, strong) NSString *applicationIdentifier;

#pragma mark - Mode

/**
 *  The mode for this command.
 */
@property (nonatomic, readonly) RLYSettingsCommandMode mode;

@end

NS_ASSUME_NONNULL_END
