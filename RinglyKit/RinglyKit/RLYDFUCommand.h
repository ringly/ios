#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Specifies the number of seconds the peripheral should wait in DFU mode before timing out.
 */
typedef NS_ENUM(NSInteger, RLYDFUCommandTimeout)
{
    /**
     *  5 seconds.
     */
    RLYDFUCommandTimeout5  = 1,
    
    /**
     *  10 seconds.
     */
    RLYDFUCommandTimeout10 = 2,
    
    /**
     *  15 seconds.
     */
    RLYDFUCommandTimeout15 = 3,
    
    /**
     *  20 seconds.
     */
    RLYDFUCommandTimeout20 = 4,
    
    /**
     *  25 seconds.
     */
    RLYDFUCommandTimeout25 = 5,
    
    /**
     *  30 seconds.
     */
    RLYDFUCommandTimeout30 = 0,
    
    /**
     *  35 seconds.
     */
    RLYDFUCommandTimeout35 = 6,
    
    /**
     *  40 seconds.
     */
    RLYDFUCommandTimeout40 = 7
};


/**
 Returns a string representation of the DFU command timeout value.

 @param DFUCommandTimeout The DFU command timeout value.
 */
RINGLYKIT_EXTERN NSString *RLYDFUCommandTimeoutToString(RLYDFUCommandTimeout DFUCommandTimeout);

/**
 *  Instructs the ring to enter DFU mode.
 */
RINGLYKIT_FINAL @interface RLYDFUCommand : NSObject <RLYCommand>

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
 *  Returns a command with the specified timeout.
 *
 *  @param timeout The number of seconds the peripheral should wait in DFU mode before timing out.
 */
-(instancetype)initWithTimeout:(RLYDFUCommandTimeout)timeout NS_DESIGNATED_INITIALIZER;

#pragma mark - Timeout
/**
 *  Specifies the number of seconds the peripheral should wait in DFU mode before timing out.
 */
@property (nonatomic, readonly) RLYDFUCommandTimeout timeout;

@end

NS_ASSUME_NONNULL_END
