#import "UIImage+Ringly.h"

@implementation UIImage (Ringly)

+(UIImage*)rly_pixelWithColor:(UIColor*)color
{
    CGSize size = CGSizeMake(1, 1);
    UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    UIGraphicsPushContext(context);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIGraphicsPopContext();

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

-(nonnull UIImage*)rly_imageWithScale:(CGFloat)scale
{
    return [UIImage imageWithCGImage:self.CGImage scale:scale orientation:self.imageOrientation];
}

@end
