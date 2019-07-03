#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Contains messages for reading logging data from a peripheral.
@protocol RLYPeripheralLogging <NSObject>

#pragma mark - Flash Log

/**
 Begins reading flash log data from a peripheral.

 @param length The length of the data to read.
 @param address The address of the data to read.
 @param error An error pointer, which will be set if the data read command cannot be sent.
 */
-(BOOL)readFlashLogOfLength:(uint16_t)length atAddress:(uint32_t)address error:(NSError**)error
    NS_SWIFT_NAME(readFlashLog(length:address:));

@end

NS_ASSUME_NONNULL_END
