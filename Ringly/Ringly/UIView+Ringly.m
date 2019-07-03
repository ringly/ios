#import <PureLayout/PureLayout.h>
#import "UIView+Ringly.h"

@implementation UIView (Ringly)

#pragma mark - Effects
-(void)rly_wiggleWithMoves:(NSUInteger)moves distance:(CGSize)distance duration:(NSTimeInterval)duration
{
    // add the final move, back to the origin
    moves++;
    
    // need at least two moves for this to be a "wiggle"
    if (moves < 2)
    {
        return;
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = duration;
    
    animation.values = [NSArray rly_mapToCount:moves withBlock:^id(NSUInteger index) {
        if (index == moves - 1)
        {
            return [NSValue valueWithCATransform3D:CATransform3DIdentity];
        }
        else
        {
            CGFloat factor = index % 2 ? 1 : -1;
            CATransform3D transform = CATransform3DMakeTranslation(factor * distance.width, factor * distance.height, 0);
            return [NSValue valueWithCATransform3D:transform];
        }
    }];
    
    animation.timingFunctions = [NSArray rly_mapToCount:moves withBlock:^id(NSUInteger index) {
        return [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    }];
    
    CGFloat perFrame = 1.0 / (moves - 2);
    animation.keyTimes = [NSArray rly_mapToCount:moves withBlock:^id(NSUInteger index) {
        if (index == 0)
        {
            return @0;
        }
        else if (index < moves - 1)
        {
            return @(perFrame / 2 + perFrame * (index - 1));
        }
        else
        {
            return @1;
        }
    }];
    
    [self.layer addAnimation:animation forKey:@"transform"];
}

-(void)rly_wiggleForFormRejection
{
    [self rly_wiggleWithMoves:7 distance:CGSizeMake(5, 0) duration:0.4];
}


#pragma mark - Separators
+(UIView*)rly_separatorViewWithHeight:(CGFloat)height color:(UIColor*)color
{
    UIView *separator = [UIView newAutoLayoutView];
    separator.backgroundColor = color;
    [separator autoSetDimension:ALDimensionHeight toSize:height];
    
    return separator;
}

@end
