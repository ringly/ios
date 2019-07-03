#import "RLYLogFunction.h"

typeof(NSLog)* RLYLogFunction = RLYLogFunctionSilent;

void RLYLogFunctionSilent(NSString *__nonnull format, ...)
{
}
