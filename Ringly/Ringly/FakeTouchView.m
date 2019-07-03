#import "FakeTouchView.h"
#import "Functions.h"

CGSize const kFakeTouchViewSize = { .width = 20, .height = 20 };

@implementation FakeTouchView

+(void)fakeTouchCenteredOnPoint:(CGPoint)point
                         ofView:(UIView*)view
            animationInDuration:(NSTimeInterval)animationInDuration
                  dwellDuration:(NSTimeInterval)dwellDuration
           animationOutDuration:(NSTimeInterval)animationOutDuration
{
    CGRect rect = CGRectMake(point.x - kFakeTouchViewSize.width / 2,
                             point.y - kFakeTouchViewSize.height / 2,
                             kFakeTouchViewSize.width,
                             kFakeTouchViewSize.height);
    
    [self fakeTouchInRect:rect
                   ofView:view
      animationInDuration:animationInDuration
            dwellDuration:dwellDuration
     animationOutDuration:animationOutDuration];
}

+(void)fakeTouchInRect:(CGRect)rect
                ofView:(UIView*)view
   animationInDuration:(NSTimeInterval)animationInDuration
         dwellDuration:(NSTimeInterval)dwellDuration
  animationOutDuration:(NSTimeInterval)animationOutDuration
{
    // create the fake touch view
    FakeTouchView *touch = [[FakeTouchView alloc] initWithFrame:rect];
    touch.transform = CGAffineTransformMakeScale(2.5, 2.5);
    touch.alpha = 0;
    [view addSubview:touch];
    
    // animate
    [UIView animateWithDuration:animationInDuration animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        touch.transform = CGAffineTransformIdentity;
        touch.alpha = 1;
    }];
    
    RLYDispatchAfterMain(animationInDuration + dwellDuration, ^{
        [UIView animateWithDuration:animationOutDuration animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            touch.alpha = 0;
            touch.transform = CGAffineTransformMakeTranslation(0.5, 0.5);
        } completion:^(BOOL finished) {
            [touch removeFromSuperview];
        }];
    });
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    UIImage *lineImage = [FakeTouchView lineImageWithSize:CGSizeMake(4, 4)
                                                thickness:1
                                                    white:1.0
                                                backAlpha:0.2 lineAlpha:0.1];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, 0.5, 0.5)];
    [[UIColor colorWithPatternImage:lineImage] set];
    [path fill];
    
    [[UIColor whiteColor] set];
    [path stroke];
}

+(UIImage*)lineImageWithSize:(CGSize)size
                   thickness:(CGFloat)thickness
                       white:(CGFloat)white
                   backAlpha:(CGFloat)backAlpha
                   lineAlpha:(CGFloat)lineAlpha
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:white alpha:backAlpha].CGColor);
    CGContextFillRect(ctx, rect);
    
    for (NSInteger i = 0; i < 3; i++)
    {
        CGRect offset = CGRectOffset(rect, (i - 1) * rect.size.width, 0);
        CGRect outset = CGRectInset(offset, -thickness, -thickness);
        
        CGContextMoveToPoint(ctx, CGRectGetMinX(outset), CGRectGetMaxY(outset));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(outset), CGRectGetMinY(outset));
        CGContextSetLineWidth(ctx, thickness);
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:white alpha:lineAlpha].CGColor);
        CGContextStrokePath(ctx);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+(void)showAtPoint:(CGPoint)point ofView:(UIView*)view completion:(void(^)())completion
{
    CGSize const size = { 50, 50 };
    CGRect const frame = CGRectMake(point.x - size.width / 2, point.y - size.height / 2, size.width, size.height);
    NSTimeInterval const duration = 0.4;
    
    UIView *container = [[UIView alloc] initWithFrame:frame];
    [view addSubview:container];
    
    CALayer *layer = [CALayer layer];
    layer.frame = container.bounds;
    
    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.cornerRadius = frame.size.width / 2;
    
    layer.shadowColor = [UIColor colorWithRed:0.125 green:0.525 blue:0.78 alpha:1].CGColor;
    layer.shadowOffset = CGSizeZero;
    layer.shadowOpacity = 1;
    layer.shadowRadius = 4;
    
    [container.layer addSublayer:layer];
    
    CABasicAnimation *frameAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    frameAnimation.fromValue = [NSValue valueWithCGSize:CGSizeZero];
    frameAnimation.toValue = [NSValue valueWithCGSize:container.bounds.size];
    frameAnimation.duration = duration;
    
    CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    radiusAnimation.fromValue = @0;
    radiusAnimation.toValue = @(frame.size.width / 2);
    radiusAnimation.duration = duration;
    
    CAKeyframeAnimation *borderAnimation = [CAKeyframeAnimation animationWithKeyPath:@"borderWidth"];
    borderAnimation.values = @[@0, @(frame.size.width / 3), @0];
    borderAnimation.duration = duration;
    
    [layer addAnimation:frameAnimation forKey:@"frame"];
    [layer addAnimation:radiusAnimation forKey:@"cornerRadius"];
    [layer addAnimation:borderAnimation forKey:@"borderWidth"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [container removeFromSuperview];
        completion();
    });
}

@end
