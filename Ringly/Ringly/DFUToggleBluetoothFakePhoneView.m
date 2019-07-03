#import "DFUToggleArrow.h"
#import "DFUToggleBluetoothFakePhoneView.h"

@interface DFUToggleBluetoothFakePhoneView ()
{
@private
    NSLayoutConstraint *_screenToTop;
    NSLayoutConstraint *_controlCenterToBottom;
    NSLayoutConstraint *_separatorHeight;
    
    UIView *_screenDark;
    UIView *_screenSeparator;
    UIView *_handle;
    UIView *_handleContents;
    UIView *_controlCenter;
    
    NSArray *_circles;
    CALayer *_centerCircleMask;
    UIImageView *_bluetoothFilledView;
}

@end

@implementation DFUToggleBluetoothFakePhoneView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        // screen contents
        _screenDark = [UIView newAutoLayoutView];
        _screenDark.backgroundColor = [UIColor colorWithRed:0 green:0.227 blue:0.518 alpha:0.2];
        [self.screen addSubview:_screenDark];
        
        _screenSeparator = [UIView newAutoLayoutView];
        _screenSeparator.backgroundColor = [UIColor whiteColor];
        [self.screen addSubview:_screenSeparator];
        
        _handle = [UIView newAutoLayoutView];
        _handle.clipsToBounds = YES;
        [self.screen addSubview:_handle];
        
        _handleContents = [UIView newAutoLayoutView];
        _handleContents.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        _handleContents.layer.borderColor = [UIColor whiteColor].CGColor;
        _handleContents.layer.borderWidth = self.lineThickness;
        [_handle addSubview:_handleContents];
        
        DFUToggleArrow *handleArrow = [DFUToggleArrow newAutoLayoutView];
        handleArrow.backgroundColor = [UIColor clearColor];
        handleArrow.arrowColor = [UIColor colorWithRed:0.118 green:0.631 blue:0.671 alpha:1];
        handleArrow.transform = CGAffineTransformMakeScale(1, -1);
        [_handle addSubview:handleArrow];
        
        _controlCenter = [UIView newAutoLayoutView];
        _controlCenter.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [self.screen addSubview:_controlCenter];
        
        DFUToggleArrow *arrow = [DFUToggleArrow newAutoLayoutView];
        arrow.backgroundColor = [UIColor clearColor];
        arrow.arrowColor = [UIColor whiteColor];
        [_controlCenter addSubview:arrow];
        
        _circles = [NSArray rly_mapToCount:5 withBlock:^id(NSUInteger i) {
            UIView *view = [UIView newAutoLayoutView];
            view.backgroundColor = [UIColor whiteColor];
            view.alpha = 0.2;
            
            [_controlCenter addSubview:view];
            
            [view autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_controlCenter withMultiplier:0.1578947368];
            [view autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:view];
            [view autoConstrainAttribute:ALAttributeLeft
                             toAttribute:ALAttributeRight
                                  ofView:_controlCenter
                          withMultiplier:(i * 0.15) + (i + 1) * 0.04];
            [view autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBottom ofView:_controlCenter withMultiplier:0.1473429952];
            
            return view;
        }];
        
        _centerCircleMask = [CALayer layer];
        _centerCircleMask.contents = (__bridge id)[UIImage imageNamed:@"ControlCenterBluetoothMask"].CGImage;
        [(UIView*)_circles[2] layer].mask = _centerCircleMask;

        _bluetoothFilledView = [UIImageView newAutoLayoutView];
        _bluetoothFilledView.image = [UIImage imageNamed:@"ControlCenterBluetooth"];
        _bluetoothFilledView.clipsToBounds = YES;
        [_controlCenter addSubview:_bluetoothFilledView];
        self.bluetoothEnabled = YES;
        
        // screen contents layout
        _screenToTop = [_screenDark autoPinEdgeToSuperviewEdge:ALEdgeTop];
        _screenToTop.priority = UILayoutPriorityDefaultHigh;
        [_screenDark autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_screenDark autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_screenDark autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:self.screen];
        
        [_handle autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_handle autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:self.screen withMultiplier:0.3010471204];
        [_handle autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:_handle withMultiplier:0.3652173913];
        [_handle autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_screenSeparator];
        
        [_handleContents autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [_handleContents autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeHeight ofView:_handle withMultiplier:2];
        
        [_screenSeparator autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_screenSeparator autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_screenSeparator autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_screenDark];
        _separatorHeight = [_screenSeparator autoSetDimension:ALDimensionHeight toSize:self.lineThickness];

        [_controlCenter autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_controlCenter autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_controlCenter autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_screenSeparator];
        [_controlCenter autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:self.screen withMultiplier:1.1];
        
        [arrow autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [arrow autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_controlCenter withMultiplier:0.08115183246];
        [arrow autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:arrow withMultiplier:0.4666666667];
        [arrow autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeBottom ofView:_controlCenter withMultiplier:0.02898550725];
        
        [handleArrow autoCenterInSuperview];
        [handleArrow autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeWidth ofView:_controlCenter withMultiplier:0.08115183246];
        [handleArrow autoConstrainAttribute:ALAttributeHeight toAttribute:ALAttributeWidth ofView:arrow withMultiplier:0.4666666667];
        
        [_bluetoothFilledView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:_circles[2]];
        [_bluetoothFilledView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:_circles[2]];
        [_bluetoothFilledView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:_circles[2]];
        [_bluetoothFilledView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:_circles[2]];
        
        _controlCenterToBottom = [_controlCenter autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [_controlCenterToBottom setPriority:UILayoutPriorityDefaultLow];
    }
    
    return self;
}

-(void)setBluetoothEnabled:(BOOL)bluetoothEnabled
{
    _bluetoothEnabled = bluetoothEnabled;
    _bluetoothFilledView.alpha = _bluetoothEnabled ? 1 : 0;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *view in _circles)
    {
        view.layer.cornerRadius = view.bounds.size.width / 2;
    }
    
    // force layout of handle so we can get the corner radius
    [_handle layoutIfNeeded];
    _handleContents.layer.cornerRadius = _handle.bounds.size.width * 0.1565217391;
    
    // force layout of central circle so the frame is the correct size
    [_circles[2] layoutIfNeeded];
    _centerCircleMask.frame = [_circles[2] bounds];
    _bluetoothFilledView.layer.cornerRadius = _bluetoothFilledView.bounds.size.width / 2;
}

-(void)setControlCenterUp:(BOOL)controlCenterUp
{
    _controlCenterUp = controlCenterUp;
    _screenToTop.priority = controlCenterUp ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    _controlCenterToBottom.priority = controlCenterUp ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    _handle.alpha = controlCenterUp ? 0 : 1;
    
    [self setNeedsLayout];
}

-(void)setLineThickness:(CGFloat)lineThickness
{
    [super setLineThickness:lineThickness];
    _handleContents.layer.borderWidth = lineThickness;
    _separatorHeight.constant = lineThickness;
}

-(CGPoint)bluetoothCenter
{
    UIView *view = _circles[2];
    return [view.superview convertPoint:view.center toView:self];
}

-(CGFloat)controlCenterHeight
{
    return _controlCenter.bounds.size.height;
}

@end
