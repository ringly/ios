#import <Foundation/Foundation.h>

typedef uint8_t RLYCommandType;

/**
 *  A command is a command written to a Ringly peripheral. It consists of a metadata byte, a command byte, a length
 *  byte, and optional additional data bytes.
 *
 *  The classes that implement the `RLYCommand` protocol provide a high-level interface to command construction, and
 *  should be used to create command objects.
 */
@protocol RLYCommand <NSObject>

/**
 *  The command's type.
 */
@property (nonatomic, readonly) RLYCommandType type;

@optional
/**
 *  Allows subclasses to provide additional data, appended to the end of their `-dataRepresentation`. The length byte
 *  will automatically be included by the superclass, so it should not be included.
 */
@property (nullable, nonatomic, readonly) NSData *extraData;

@end
