#import <UIKit/UIKit.h>

@interface UIImage (Ringly)

#pragma mark - Color Images
/**
 *  Returns a 1x1 image of the specified color.
 *
 *  @param color The color of the image.
 */
+(nonnull UIImage*)rly_pixelWithColor:(nonnull UIColor*)color;

/**
 *  Returns an image with an altered `scale`.
 *
 *  @param scale The scale to use.
 */
-(nonnull UIImage*)rly_imageWithScale:(CGFloat)scale;

@end
