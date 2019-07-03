#import "RLYANCSNotification.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Parses ANCS version 2 messages. It should not be necessary to create an instance of this class.
 *
 *  This class is internal, and should not be necessary outside of RinglyKit.
 */
@interface RLYANCSV2Parser : NSObject

#pragma mark - Initialization

/**
 *  `RLYANCSV2Parser` cannot be initialized - it is a container for class messages.
 */
+(instancetype)new NS_UNAVAILABLE;

/**
 *  `RLYANCSV2Parser` cannot be initialized - it is a container for class messages.
 */
-(instancetype)init NS_UNAVAILABLE;

#pragma mark - Parsing

/**
 *  Parses ANCS version 2 data into an ANCS notification.
 *
 *  @param data                       The data to parse.
 *  @param notificationAttributeCount The notification attribute count.
 *  @param applicationAttributeCount  The application attribute count.
 *  @param error                      An error pointer, to be set if parsing fails.
 */
+(nullable RLYANCSNotification*)parseData:(NSData*)data
           withNotificationAttributeCount:(NSUInteger)notificationAttributeCount
                applicationAttributeCount:(NSUInteger)applicationAttributeCount
                                    error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
