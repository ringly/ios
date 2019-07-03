#import <Foundation/Foundation.h>
#import "RLYDefines.h"

/**
 *  Allows users of the library to customize logging. The default value is `RLYLogFunctionSilent`, which performs no
 *  logging.
 *
 *  This pointer must not be set to `nil`. If you have enabled logging and wish to disable it, set this pointer to
 *  `RLYLogFunctionSilent`.
 */
RINGLYKIT_EXTERN typeof(NSLog)* __nonnull RLYLogFunction;

/**
 *  A function which accepts log parameters and does nothing.
 */
RINGLYKIT_EXTERN void RLYLogFunctionSilent(NSString *__nonnull format, ...);
