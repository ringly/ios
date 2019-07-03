#import "DFUToggleArrow.h"

@implementation DFUToggleArrow

-(void)setArrowColor:(UIColor*)arrowColor
{
    _arrowColor = arrowColor;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    CGFloat thickness = self.bounds.size.height / 5;
    CGRect inset = CGRectInset(self.bounds, thickness, thickness);

    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = thickness;
    [path moveToPoint:CGPointMake(CGRectGetMinX(inset), CGRectGetMinY(inset))];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(inset), CGRectGetMaxY(inset))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(inset), CGRectGetMinY(inset))];

    [_arrowColor setStroke];

    [path stroke];
}

@end
