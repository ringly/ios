#import "DFUFakePhoneView.h"
#import "DFULightningView.h"

CGFloat const kDFULightingViewPlugHeight = 18;

@implementation DFULightningView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        UIView *top = [UIView newAutoLayoutView];
        top.layer.borderColor = [UIColor whiteColor].CGColor;
        top.layer.borderWidth = kDFUFakePhoneViewLineThickness;
        [self addSubview:top];

        UIView *middle = [UIView newAutoLayoutView];
        middle.layer.borderColor = [UIColor whiteColor].CGColor;
        middle.layer.borderWidth = kDFUFakePhoneViewLineThickness;
        [self addSubview:middle];

        UIView *bottom = [UIView newAutoLayoutView];
        bottom.layer.borderColor = [UIColor whiteColor].CGColor;
        bottom.layer.borderWidth = kDFUFakePhoneViewLineThickness;
        [self addSubview:bottom];

        // layout
        [top autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [top autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [top autoSetDimensionsToSize:CGSizeMake(19, kDFULightingViewPlugHeight)];

        [middle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:top withOffset:-kDFUFakePhoneViewLineThickness];
        [middle autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [middle autoSetDimensionsToSize:CGSizeMake(28, 35)];

        [bottom autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:middle withOffset:-kDFUFakePhoneViewLineThickness];
        [bottom autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [bottom autoSetDimension:ALDimensionWidth toSize:10];
        [bottom autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-kDFUFakePhoneViewLineThickness];
    }

    return self;
}

@end
