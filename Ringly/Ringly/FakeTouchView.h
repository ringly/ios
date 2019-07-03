#import <UIKit/UIKit.h>

FOUNDATION_EXTERN CGSize const kFakeTouchViewSize;

@interface FakeTouchView : UIView

+(void)fakeTouchCenteredOnPoint:(CGPoint)point
                         ofView:(UIView*)view
            animationInDuration:(NSTimeInterval)animationInDuration
                  dwellDuration:(NSTimeInterval)dwellDuration
           animationOutDuration:(NSTimeInterval)animationOutDuration;

+(void)fakeTouchInRect:(CGRect)rect
                ofView:(UIView*)view
   animationInDuration:(NSTimeInterval)animationInDuration
         dwellDuration:(NSTimeInterval)dwellDuration
  animationOutDuration:(NSTimeInterval)animationOutDuration;

+(void)showAtPoint:(CGPoint)point ofView:(UIView*)view completion:(void(^)())completion;

@end

