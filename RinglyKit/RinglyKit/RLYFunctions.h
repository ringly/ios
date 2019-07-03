#import <CoreBluetooth/CoreBluetooth.h>
#import <RinglyKit/RLYDefines.h>

#pragma mark - Functional

/**
 *  Returns `YES` if `block` returns `YES` for all of the objects in `enumerable`.
 *
 *  @param enumerable The enumerable.
 *  @param block      The block.
 */
RINGLYKIT_EXTERN BOOL RLYAny(id<NSFastEnumeration> enumerable, BOOL(^block)(id object));

/**
 *  Returns the first object in enumerable for which `block` returns `YES`, or `nil` if no objects pass the test.
 *
 *  @param enumerable The enumerable.
 *  @param block      The block.
 */
RINGLYKIT_EXTERN id RLYFirstMatching(id<NSFastEnumeration> enumerable, BOOL(^block)(id object));

/**
 *  Generates a dictionary from an array.
 *
 *  @param array The array to use.
 *  @param block A block. Before returning, the `key` and `value` pointers should be set.
 */
RINGLYKIT_EXTERN NSDictionary *RLYMapToDictionary(NSArray *array, void(^block)(id object, id<NSCopying> *key, id *value));

#pragma mark - CBPeripheral

/**
 *  Returns `YES` if the peripheral passed is a Ringly device.
 *
 *  @param peripheral The peripheral.
 */
RINGLYKIT_EXTERN BOOL RLYCBPeripheralIsRingly(CBPeripheral *peripheral);

/**
 *  Returns `YES` if the characteristic properties include notify or indicate.
 *
 *  @param properties The characteristic properties.
 */
RINGLYKIT_EXTERN BOOL RLYSupportsNotifyOrIndicate(CBCharacteristicProperties properties);

/**
 *  Returns `YES` if the characteristic properties include notify or indicate, but encryption is required.
 *
 *  @param properties The characteristics properties.
 */
RINGLYKIT_EXTERN BOOL RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicProperties properties);

#pragma mark - String Data

/**
 *  Returns a string that will fit within `size` bytes when converted to UTF-8 data.
 *
 *  @param string The input string.
 *  @param size   The maximum size in a UTF-8 representation.
 */
RINGLYKIT_EXTERN NSString *RLYStringFittingInUTF8Bytes(NSString *string, size_t size);

#pragma mark - Version Numbers

/**
 *  Splits a version number string into an array of components.
 *
 *  @param versionNumber The version number to split.
 */
RINGLYKIT_EXTERN NSArray<NSString*> *RLYVersionNumberComponents(NSString *versionNumber);

/**
 *  Compares two version number strings.
 *
 *  @param first  The first version number string.
 *  @param second The second version number string.
 */
RINGLYKIT_EXTERN NSComparisonResult RLYCompareVersionNumbers(NSString *first, NSString *second);

#pragma mark - ANCS Version 1

/**
 *  Scans a data object for an ANCS v1 header.
 *
 *  @param data The data to scan.
 */
RINGLYKIT_EXTERN NSData *RLYScanANCSV1Header(NSData *data);

#pragma mark - Data String Parsing

/**
 *  Returns a subdata to the first null character byte.
 *
 *  @param data The data to return a subdata of.
 */
RINGLYKIT_EXTERN NSData *RLYSubdataToFirstNull(NSData *data);

/**
 *  Drops bytes from the end of `data` until it parses as a valid UTF-8 string. This function cannot return `nil`, as a
 *  data of length `0` will always correctly parse to the empty string.
 *
 *  @param data The data value.
 */
RINGLYKIT_EXTERN NSString *RLYFindValidUTF8Prefix(NSData *data);

/**
 *  Drops bytes from the start of `data` until it parses as a valid UTF-8 string. This function cannot return `nil`, as
 *  a data of length `0` will always correctly parse to the empty string.
 *
 *  @param data The data value.
 */
RINGLYKIT_EXTERN NSString *RLYFindValidUTF8Suffix(NSData *data);

#pragma mark - Data

/**
 *  Returns `YES` if all bytes of `data` match `value`.
 *
 *  @param data  The data.
 *  @param value The value to match.
 */
RINGLYKIT_EXTERN BOOL RLYAllBytesMatch(NSData *data, uint8_t value);

/**
 Returns a data object for reading the flash log.

 @param length The length of the data to read.
 @param address The address of the data to read.
 */
RINGLYKIT_EXTERN NSData *RLYDataForReadingFlashLog(uint16_t length, uint32_t address);

#pragma mark - Messages

/**
 *  Parses a setting confirmation message and executes the appropriate block.
 *
 *  @param message   The message data.
 *  @param confirmed A block to execute if the message is a "confirmed" message.
 *  @param deleted   A block to execute if the message is a "deleted" message.
 *  @param cleared   A block to execute if the message is a "cleared" message.
 */
RINGLYKIT_EXTERN void RLYParseConfirmationMessage(NSData *message,
                                                  void(^confirmed)(),
                                                  void(^deleted)(),
                                                  void(^cleared)());

#pragma mark - Breakpoints

/**
 *  Calls `RLYBreakpoint` if `condition` is `YES`.
 *
 *  @param condition The condition.
 */
RINGLYKIT_EXTERN void RLYBreakpointIf(BOOL condition);

/**
 *  A function that debuggers can break on.
 */
RINGLYKIT_EXTERN void RLYBreakpoint(void);
