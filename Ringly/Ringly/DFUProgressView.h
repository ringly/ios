#import <UIKit/UIKit.h>

typedef struct
{
    NSUInteger current;
    NSUInteger total;
} DFUProgressViewUpdateNumber;

static inline DFUProgressViewUpdateNumber DFUProgressViewUpdateNumberMake(NSUInteger current, NSUInteger total)
{
    DFUProgressViewUpdateNumber number = { current, total };
    return number;
}

@interface DFUProgressView: UIView

/**
 *  The current determinate progress. This value should be between `0` and `100`. If this value is exactly `0` or `100`,
 *  the indeterminate progress indicator will be displayed.
 */
@property (nonatomic) NSInteger progress;

@end
