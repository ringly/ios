#import <RinglyKit/RinglyKit.h>

/**
 *  A command confirming to the peripheral that the application has received a message, but instructing it to perform
 *  no action in response to the message.
 */
RINGLYKIT_FINAL @interface RLYNoActionCommand : NSObject <RLYCommand>

@end
