#import "RLYActivityTrackingUpdate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLYActivityTrackingUpdate ()

#pragma mark - Parsing Data

/**
 *  Synchronously parses data from the activity tracking data characteristic.
 *
 *  @param data               The data to parse.
 *  @param updateCallback     A callback to call for each successful result.
 *  @param errorCallback      A callback to call for each failed result.
 *  @param completionCallback A callback to call if the data indicates that all available data has been read.
 */
+(void)parseActivityTrackingCharacteristicData:(NSData*)data
                            withUpdateCallback:(__attribute__((noescape)) void(^)(RLYActivityTrackingUpdate *update))updateCallback
                                 errorCallback:(__attribute__((noescape)) void(^)(NSError *error))errorCallback
                            completionCallback:(__attribute__((noescape)) void(^)())completionCallback;

/**
 *  Parses an activity tracking update value from a byte array.
 *
 *  It is possible that a valid value will not be present at the offset, but this will not be an error condition, so the
 *  error pointer will remain unset. This will occur when the minute timestamp is `0`, as these records are used for
 *  storing information about firmware resets.
 *
 *  @param offset The offset into the byte array.
 *  @param bytes  The byte array.
 *  @param error  An error pointer.
 */
+(nullable RLYActivityTrackingUpdate*)updateAtOffset:(size_t)offset ofBytes:(uint8_t*)bytes withError:(NSError**)error;

/**
 *  Parses an activity tracking date interval from a byte array.
 *
 *  @param offset The offset into the byte array.
 *  @param bytes  The byte array.
 */
+(RLYActivityTrackingMinute)intervalAtOffset:(size_t)offset ofBytes:(uint8_t*)bytes;

@end

NS_ASSUME_NONNULL_END
