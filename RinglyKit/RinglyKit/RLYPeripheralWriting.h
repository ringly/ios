#import "RLYCommand.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Contains messages and properties allowing commands to be written to a peripheral.
 *
 *  For writing a configuration hash, see `RLYPeripheralConfigurationHashing`.
 */
@protocol RLYPeripheralWriting <NSObject>

#pragma mark - Commands

/**
 *  Writes a `Command` to the peripheral.
 *
 *  @param command The command to write to the peripheral. This parameter may not be `nil`.
 */
-(void)writeCommand:(id<RLYCommand>)command NS_SWIFT_NAME(write(command:));

/**
 *  Returns `YES` if commands can be written to the peripheral.
 */
@property (nonatomic, readonly) BOOL canWriteCommands;

#pragma mark - Clear Bond

/**
 *  Uses the correct method to clear the peripheral's bond, based on the firmware features available.
 */
-(void)writeClearBond;

@end

NS_ASSUME_NONNULL_END
