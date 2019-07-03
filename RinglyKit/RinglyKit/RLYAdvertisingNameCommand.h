#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Allows altering the advertising name of the peripheral.
 *
 *  This command is reliable, but iOS caches the names of peripherals. Therefore, writing this command to a peripheral
 *  will not visibly change its advertising name.
 */
RINGLYKIT_FINAL @interface RLYAdvertisingNameCommand : NSObject <RLYCommand>

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
 *  Initializes an advertising name command.
 *
 *  @param shortName   The short name to use for the peripheral. This should be a four-character string, but this is not
 *                     currently enforced at runtime. In the future, an exception may be thrown if this parameter is not
 *                     exactly four characters long.
 *
 *                     Short names for peripherals can be obtained from the `RLYPeripheralStyle` enumeration with the
 *                     `RLYPeripheralStyleToShortName` function. It is not required to use an explicitly supported
 *                     short name, however.
 *  @param diamondClub If the peripheral should report itself as diamond club.
 */
-(instancetype)initWithShortName:(NSString*)shortName diamondClub:(BOOL)diamondClub NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The short name to use for the peripheral.
 */
@property (readonly, nonatomic, strong) NSString *shortName;

/**
 *  If the peripheral should report itself as diamond club.
 */
@property (readonly, nonatomic, getter=isDiamondClub) BOOL diamondClub;

@end

NS_ASSUME_NONNULL_END
