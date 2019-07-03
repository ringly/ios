#import "RLYCommand.h"
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Sets the tap parameters of a peripheral. This affects how a peripheral interprets taps.
 */
RINGLYKIT_FINAL @interface RLYTapParametersCommand : NSObject <RLYCommand>

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
 *  Initializes a tap parameters command.
 *
 *  @param threshold The tap threshold.
 *  @param timeLimit The tap time limit.
 *  @param latency   The tap latency.
 *  @param window    The tap window.
 *  @param field5    Field #5.
 *  @param field6    Field #6.
 *  @param field7    Field #7.
 *  @param field8    Field #8.
 *  @param field9    Field #9.
 *  @param field10   Field #10.
 */
-(instancetype)initWithThreshold:(uint8_t)threshold
                       timeLimit:(uint8_t)timeLimit
                         latency:(uint8_t)latency
                          window:(uint8_t)window
                          field5:(uint8_t)field5
                          field6:(uint8_t)field6
                          field7:(uint8_t)field7
                          field8:(uint8_t)field8
                          field9:(uint8_t)field9
                         field10:(uint8_t)field10 NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

/**
 *  The tap threshold.
 */
@property (nonatomic, readonly) uint8_t threshold;

/**
 *  The tap time limit.
 */
@property (nonatomic, readonly) uint8_t timeLimit;

/**
 *  The tap latency.
 */
@property (nonatomic, readonly) uint8_t latency;

/**
 *  The tap window.
 */
@property (nonatomic, readonly) uint8_t window;

/**
 *  Field #5.
 */
@property (nonatomic, readonly) uint8_t field5;

/**
 *  Field #6.
 */
@property (nonatomic, readonly) uint8_t field6;

/**
 *  Field #7.
 */
@property (nonatomic, readonly) uint8_t field7;

/**
 *  Field #8.
 */
@property (nonatomic, readonly) uint8_t field8;

/**
 *  Field #9.
 */
@property (nonatomic, readonly) uint8_t field9;

/**
 *  Field #10.
 */
@property (nonatomic, readonly) uint8_t field10;

@end

NS_ASSUME_NONNULL_END
