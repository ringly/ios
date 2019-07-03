#import "RinglyAlertShadowView.h"

@implementation RinglyAlertShadowView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.angle = M_PI_4;
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    // view metrics
    CGRect const bounds = self.bounds;
    
    // create path
    CGMutablePathRef path = CGPathCreateMutable();
    
    // circle midpoints
    CGPoint const leftCircle = {
        CGRectGetMinX(rect) + _radius,
        CGRectGetMaxY(rect) - _radius - _shadowSize.height
    };
    
    CGPoint const bottomCircle = {
        CGRectGetMinX(rect) + _radius + tan(_angle) * _shadowSize.height,
        CGRectGetMaxY(rect) - _radius
    };
    
    CGPoint const rightCircle = {
        CGRectGetMaxX(rect) - _radius,
        CGRectGetMinY(rect) + _radius + tan(_angle) * _shadowSize.width
    };
    
    CGPoint const topCircle = {
        CGRectGetMaxX(rect) - _radius - _shadowSize.width,
        CGRectGetMinY(rect) + _radius
    };
    
    
    // angles
    CGFloat const startAngle = _angle + M_PI;
    CGFloat const startMidAngle = (startAngle + 3 * M_PI_2) / 2.0;
    
    CGFloat const endAngle = M_PI_2 - _angle;
    CGFloat const endMidAngle = (endAngle + 0) / 2.0;
    
    // bottom left corner
    CGPathMoveToPoint(path,
                      NULL,
                      leftCircle.x + cos(startAngle) * _radius,
                      leftCircle.y - sin(startAngle) * _radius);
    
    CGPathAddLineToPoint(path,
                         NULL,
                         bottomCircle.x + cos(startAngle) * _radius,
                         bottomCircle.y - sin(startAngle) * _radius);
    
    CGPathAddArcToPoint(path,
                        NULL,
                        bottomCircle.x + cos(startMidAngle) * _radius,
                        bottomCircle.y - sin(startMidAngle) * _radius,
                        bottomCircle.x,
                        bottomCircle.y + _radius,
                        _radius);
    
    // bottom right corner
    CGPathAddLineToPoint(path,
                         NULL,
                         CGRectGetMaxX(bounds) - _radius,
                         CGRectGetMaxY(bounds));
    
    CGPathAddArcToPoint(path,
                        NULL,
                        CGRectGetMaxX(bounds),
                        CGRectGetMaxY(bounds),
                        CGRectGetMaxX(bounds),
                        CGRectGetMaxY(bounds) - _radius,
                        _radius);
    
    // top right corner
    CGPathAddLineToPoint(path,
                         NULL,
                         rightCircle.x + _radius,
                         rightCircle.y);
    
    CGPathAddArcToPoint(path,
                        NULL,
                        rightCircle.x + cos(endMidAngle) * _radius,
                        rightCircle.y - sin(endMidAngle) * _radius,
                        rightCircle.x + cos(endAngle) * _radius,
                        rightCircle.y - sin(endAngle) * _radius,
                        _radius);
    
    CGPathAddLineToPoint(path,
                         NULL,
                         topCircle.x + cos(endAngle) * _radius,
                         topCircle.y - sin(endAngle) * _radius);
    
    // close
    CGPathCloseSubpath(path);
    
    // draw shadow
    CGContextAddPath(UIGraphicsGetCurrentContext(), path);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), _color.CGColor);
    CGContextFillPath(UIGraphicsGetCurrentContext());
    
    // clean up
    CGPathRelease(path);
}

@end
