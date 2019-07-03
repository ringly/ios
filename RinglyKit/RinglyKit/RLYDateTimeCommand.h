#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Informs the peripheral of the current date.
 */
RINGLYKIT_FINAL @interface RLYDateTimeCommand : NSObject <RLYCommand>

#pragma mark - Initialization

/**
 *  Initializes a `RLYDateTimeCommand` with the current date.
 */
-(instancetype)init;

/**
 *  Initializes a `RLYDateTimeCommand`.
 *
 *  @param date The date to use.
 */
-(instancetype)initWithDate:(NSDate*)date NS_DESIGNATED_INITIALIZER;

#pragma mark - Date

/**
 *  The date.
 */
@property (nonatomic, readonly, strong) NSDate *date;

@end

NS_ASSUME_NONNULL_END
