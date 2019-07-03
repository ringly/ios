#import <UIKit/UIKit.h>

@interface RinglyAlertShadowView : UIView

@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGSize shadowSize;
@property (nullable, nonatomic, strong) UIColor *color;

@end
