#import "RLYANCSNotification.h"

NS_ASSUME_NONNULL_BEGIN

@class RLYANCSV1Parser;

/**
 *  Includes messages sent to delegates of `RLYANCSV1Parser` objects.
 */
@protocol RLYANCSV1ParserDelegate <NSObject>

/**
 *  Notifies the delegate that the parser has finished parsing a notification.
 *
 *  @param parser       The parser.
 *  @param notification The new notification.
 */
-(void)ANCSV1Parser:(RLYANCSV1Parser*)parser parsedNotification:(RLYANCSNotification*)notification;

/**
 *  Notifies the delegate that the parser attempted to parse a notification, but failed.
 *
 *  @param parser The parser.
 *  @param error  An error object describing the failure. The error domain will be `RLYANCSV1ErrorDomain`, and the error
 *                code will be a value from the `RLYANCSV1ErrorCode` enumeration.
 */
-(void)ANCSV1Parser:(RLYANCSV1Parser *)parser failedToParseNotificationWithError:(NSError*)error;

@end

/**
 *  Parses ANCS notifications from a Ringly peripheral. This class is used internally by `RLYPeripheral`, and it
 *  shouldn't be necessary to use it externally.
 *
 *  @see RLYPeripheral
 *  @see RLYANCSNotification
 */
@interface RLYANCSV1Parser : NSObject

#pragma mark - Initialization

/**
 *  Initializes a parser with a `nil` year/month date.
 */
-(instancetype)init;

/**
 *  Initializes an ANCS version 1 parser.
 *
 *  Due to memory constraints, version 1 peripherals do not include the current month and year in the dates that they
 *  send. Therefore, the parser needs a date to pull that information from.
 *
 *  @param yearMonthDate The date to pull the current month and date from. If `nil`, the date at the time of parsing
 *                       will be used, which will be different for each parsed notification. This should be the desired
 *                       behavior in almost all situations.
 */
-(instancetype)initWithYearMonthDate:(nullable NSDate*)yearMonthDate NS_DESIGNATED_INITIALIZER;

#pragma mark - Delegation

/**
 *  The delegate for this ANCS parser.
 */
@property (nonatomic, weak, nullable) id<RLYANCSV1ParserDelegate> delegate;

#pragma mark - ANCS Data

/**
 *  Appends data to the ANCS parser. This can result in notifying the delegate of a newly parsed notification.
 *
 *  @param data The data to append.
 */
-(void)appendData:(NSData*)data;

#pragma mark - Flags

/**
 *  Enables the parsing of flags data.
 */
@property (nonatomic) BOOL includeFlags;

@end

NS_ASSUME_NONNULL_END
