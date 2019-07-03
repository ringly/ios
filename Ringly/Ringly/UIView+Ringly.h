#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Ringly)

#pragma mark - Effects
/**
 *  Wiggles the view back and forth.
 *
 *  @param moves    The number of total wiggles.
 *  @param distance The distance of each wiggle. Will be negated for every other wiggle.
 *  @param duration The total duration of wiggling.
 */
-(void)rly_wiggleWithMoves:(NSUInteger)moves distance:(CGSize)distance duration:(NSTimeInterval)duration;

/**
 *  Performs a standard wiggle for form rejection.
 */
-(void)rly_wiggleForFormRejection;

#pragma mark - Separators
/**
 *  Returns a separator view with the specified height.
 *
 *  @param height The height, in points, of the separator view.
 *  @param color The background color of the separator view.
 */
+(UIView*)rly_separatorViewWithHeight:(CGFloat)height color:(UIColor*)color;

@end

NS_ASSUME_NONNULL_END
