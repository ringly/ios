#import "DFUFakePhoneView.h"

@interface DFUFakePhoneView ()
{
@private
    UIView *_speaker;
    UIView *_homeOuter;
    UIView *_homeInner;
}

@end

CGFloat const kDFUFakePhoneViewLineThickness = 1.5;

@implementation DFUFakePhoneView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIColor *borderColor = [UIColor whiteColor];
        
        self.layer.borderColor = borderColor.CGColor;
        
        // phone contents
        _speaker = [UIView newAutoLayoutView];
        _speaker.layer.borderColor = borderColor.CGColor;
        [self addSubview:_speaker];
        
        UIView *topSpacer = [UIView newAutoLayoutView];
        [self addSubview:topSpacer];
        
        _screen = [UIView newAutoLayoutView];
        _screen.layer.borderColor = borderColor.CGColor;
        _screen.clipsToBounds = YES;
        [self addSubview:_screen];
        
        UIView *bottomSpacer = [UIView newAutoLayoutView];
        [self addSubview:bottomSpacer];
        
        _homeOuter = [UIView newAutoLayoutView];
        _homeOuter.layer.borderColor = borderColor.CGColor;
        [self addSubview:_homeOuter];
        
        _homeInner = [UIView newAutoLayoutView];
        _homeInner.layer.borderColor = borderColor.CGColor;
        [self addSubview:_homeInner];
        
        // layout
        [_speaker autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:self withMultiplier:0.1751152074];
        [_speaker autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:_speaker withMultiplier:0.1756756757];
        [_speaker autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:topSpacer];
        [_speaker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [topSpacer autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [topSpacer autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:self withMultiplier:0.2949308756];
        
        [bottomSpacer autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [bottomSpacer autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:self withMultiplier:0.2949308756];
        
        [_screen autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:self withMultiplier:0.8801843318];
        [_screen autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_screen autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:topSpacer];
        [_screen autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:bottomSpacer];
        
        // match the aspect ratio of the phone we're actually on
        CGSize screen = [UIScreen mainScreen].bounds.size;
        CGFloat ratio = MIN(1.6, screen.height / screen.width);
        
        [_screen autoConstrainAttribute:ALAttributeHeight
                            toAttribute:ALAttributeWidth
                                 ofView:_screen
                         withMultiplier:ratio];
        
        [_homeOuter autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:bottomSpacer];
        [_homeOuter autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:self withMultiplier:0.1770114943];
        [_homeOuter autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:_homeOuter];
        [_homeOuter autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [_homeInner autoConstrainAttribute:ALAttributeVertical toAttribute:ALAttributeVertical ofView:_homeOuter];
        [_homeInner autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:_homeOuter];
        [_homeInner autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_homeOuter withMultiplier:0.7402597403];
        [_homeInner autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_homeOuter withMultiplier:0.7402597403];

        // initalize line thickness
        self.lineThickness = kDFUFakePhoneViewLineThickness;
    }
    
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.bounds.size.width * 0.1428571429;
    
    _homeOuter.layer.cornerRadius = _homeOuter.bounds.size.width / 2;
    _homeInner.layer.cornerRadius = _homeInner.bounds.size.width / 2;
}

-(void)setLineThickness:(CGFloat)lineThickness
{
    _lineThickness = lineThickness;

    self.layer.borderWidth = lineThickness;

    _screen.layer.borderWidth = lineThickness;
    _screen.layer.cornerRadius = lineThickness;

    _speaker.layer.borderWidth = lineThickness;
    _speaker.layer.cornerRadius = lineThickness;

    _homeInner.layer.borderWidth = lineThickness;
    _homeOuter.layer.borderWidth = lineThickness;
}

-(CGSize)intrinsicContentSize
{
    return CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
}

@end
