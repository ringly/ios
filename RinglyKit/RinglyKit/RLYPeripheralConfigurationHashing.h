#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Adds functionality to read and write a configuration hash to a peripheral.
 *
 *  The configuration hash can be used to verify that the peripheral's settings match the current desired settings,
 *  without the peripheral performing any hashing logic. After writing settings to a peripheral, update its hash value.
 *  Then, after reconnecting, read the configuration hash again, and compare with the current local hash.
 *
 *  The configuration hash is a 64-bit value (`uint64_t`).
 */
@protocol RLYPeripheralConfigurationHashing <NSObject>

#pragma mark - Writing

/**
 *  Writes a value to the configuration hash characteristic.
 *
 *  @param hash  The hash value to write.
 *  @param error An error pointer, which will be set if the hash value cannot be written.
 */
-(BOOL)writeConfigurationHash:(uint64_t)hash error:(NSError**)error;

#pragma mark - Reading

/**
 *  Reads the current state of the configuration hash characteristic.
 *
 *  The configuration hash is not stored in memory by `RLYPeripheral`. It must be manually read.
 *
 *  @param completion A block to execute upon successful completion. The block's parameter is a 64-bit unsigned integer,
 *                    the value of the configuration hash characteristic.
 *  @param failure    A block to execute upon failure. The block's parameter is an error object.
 */
-(void)readConfigurationHashWithCompletion:(void(^)(uint64_t hash))completion failure:(void(^)(NSError *error))failure
    NS_SWIFT_NAME(readConfigurationHash(completion:failure:));

@end

NS_ASSUME_NONNULL_END
