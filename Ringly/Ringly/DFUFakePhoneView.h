#import <UIKit/UIKit.h>

@interface DFUFakePhoneView : UIView

@property (nonatomic) CGFloat lineThickness;
@property (nonatomic, readonly, strong) UIView *screen;

@end

FOUNDATION_EXTERN CGFloat const kDFUFakePhoneViewLineThickness;
