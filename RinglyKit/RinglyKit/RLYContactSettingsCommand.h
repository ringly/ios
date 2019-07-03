#import "RLYColor.h"
#import "RLYCommand.h"
#import "RLYSettingsCommandMode.h"
#import "RLYVibration.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Updates the notification settings for a contact.
 */
RINGLYKIT_FINAL @interface RLYContactSettingsCommand : NSObject <RLYCommand>

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
 *  Initializes a contact settings command with the specified contact name.
 *
 *  @param mode        The command mode to use.
 *  @param contactName The contact name to add.
 *  @param color       The color to use for the contact.
 */
-(instancetype)initWithMode:(RLYSettingsCommandMode)mode
                contactName:(NSString*)contactName
                      color:(RLYColor)color NS_DESIGNATED_INITIALIZER;

#pragma mark - Creation

/**
 *  Returns an "add" command with the specified contact name.
 *
 *  @param contactName The contact name to add.
 *  @param color       The color to use for the contact.
 */
+(instancetype)addCommandWithContactName:(NSString*)contactName color:(RLYColor)color;

/**
 *  Returns a "delete" command with the specified application identifier.
 *
 *  @param contactName The contact name to delete.
 */
+(instancetype)deleteCommandWithContactName:(NSString*)contactName;

#pragma mark - Contact Name

/**
 *  The contact name for this command.
 */
@property (nonatomic, readonly, strong) NSString *contactName;

#pragma mark - Mode

/**
 *  The mode for this command.
 */
@property (nonatomic, readonly) RLYSettingsCommandMode mode;

@end

NS_ASSUME_NONNULL_END
