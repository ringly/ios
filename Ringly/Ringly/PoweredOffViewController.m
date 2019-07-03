#import "PoweredOffViewController.h"
#import "DFUToggleBluetoothFakePhoneView.h"
#import "FakeTouchView.h"
#import "Functions.h"
#import "Ringly-Swift.h"

typedef NS_ENUM(NSInteger, PoweredOffAnimationPhase)
{
    // the start of the animation - nothing dynamic visible
    PoweredOffAnimationPhaseStart,
    
    // the instruction to swipe up appears
    PoweredOffAnimationPhaseSwipeUp,
    
    // the first fake touch is shown
    PoweredOffAnimationPhaseSwipingUpFirst,
    
    // the second fake touch is shown, and control center appears
    PoweredOffAnimationPhaseSwipingUpSecond,
    
    // the instruction to tap the center circle appears
    PoweredOffAnimationPhasePowerOn,
    
    // a fake touch icon appears over the second circle
    PoweredOffAnimationPhaseFakeTap,
    
    // the center circle is "tapped" and powers on
    PoweredOffAnimationPhasePoweredOn,
    
    // done, ready to reset
    PoweredOffAnimationPhaseDone
};

typedef struct
{
    NSTimeInterval animationTime;
    NSTimeInterval delayTime;
} PhaseProperties;

static inline PhaseProperties PhasePropertiesMake(NSTimeInterval animationTime, NSTimeInterval delayTime)
{
    PhaseProperties properties = {
        .animationTime = animationTime,
        .delayTime = delayTime
    };
    
    return properties;
}

static inline PhaseProperties PropertiesForPhase(PoweredOffAnimationPhase phase)
{
    switch (phase)
    {
        case PoweredOffAnimationPhaseStart:
            return PhasePropertiesMake(0.25, 0.75);
            
        case PoweredOffAnimationPhaseSwipeUp:
            return PhasePropertiesMake(0.25, 0.75);
            
        case PoweredOffAnimationPhaseSwipingUpFirst:
            return PhasePropertiesMake(0.75, 0.25);
            
        case PoweredOffAnimationPhaseSwipingUpSecond:
            return PhasePropertiesMake(0.75, 0.75);
            
        case PoweredOffAnimationPhasePowerOn:
            return PhasePropertiesMake(0.25, 0.75);
            
        case PoweredOffAnimationPhaseFakeTap:
            return PhasePropertiesMake(0.5, 0);
            
        case PoweredOffAnimationPhasePoweredOn:
            return PhasePropertiesMake(0.25, 1);
            
        case PoweredOffAnimationPhaseDone:
            return PhasePropertiesMake(0, 1);
    }
}

@interface PoweredOffViewController ()

// fake phone area
@property (nonatomic, strong) DFUToggleBluetoothFakePhoneView *fakePhoneView;
@property (nonatomic, strong) UILabel *swipeUpLabel;
@property (nonatomic, strong) UILabel *tapLabel;

@property (nonatomic) BOOL viewIsVisible;
@property (nonatomic) BOOL alreadyAnimating;

@property (nonatomic) PoweredOffAnimationPhase animationPhase;

@end

@implementation PoweredOffViewController

#pragma mark - View Loading
-(void)loadView
{
    UIView *view = [UIView new];
    self.view = view;
    
    // add the fake phone view
    UIView *phoneContainer = [UIView newAutoLayoutView];
    [view addSubview:phoneContainer];
//    [phoneContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
//    [phoneContainer autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
    [phoneContainer autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [phoneContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    _fakePhoneView = [DFUToggleBluetoothFakePhoneView newAutoLayoutView];
    _fakePhoneView.lineThickness = 1;
    [phoneContainer addSubview:_fakePhoneView];

    [_fakePhoneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_fakePhoneView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [_fakePhoneView autoSetDimension:ALDimensionWidth toSize:92];
    
    // add instruction labels
    UIView *labelsContainer = [UIView newAutoLayoutView];
    [phoneContainer addSubview:labelsContainer];
    
    [labelsContainer autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [labelsContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [labelsContainer autoAlignAxis:ALAxisHorizontal toSameAxisOfView:_fakePhoneView];
    [labelsContainer autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_fakePhoneView withOffset:30];
    [labelsContainer autoSetDimension:ALDimensionWidth toSize:150];
    
    _swipeUpLabel = [UILabel newAutoLayoutView];
    _swipeUpLabel.font = [UIFont gothamBookWithSize:13];
    _swipeUpLabel.textColor = [UIColor whiteColor];
    _swipeUpLabel.text = @"First, swipe up twice from the bottom of your phone's screen.";
    _swipeUpLabel.numberOfLines = 0;
    [labelsContainer addSubview:_swipeUpLabel];
    [_swipeUpLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    _tapLabel = [UILabel newAutoLayoutView];
    _tapLabel.font = _swipeUpLabel.font;
    _tapLabel.textColor = _swipeUpLabel.textColor;
    _tapLabel.text = @"Then, tap the center icon to enable Bluetooth.";
    _tapLabel.numberOfLines = 0;
    [labelsContainer addSubview:_tapLabel];
    [_tapLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [_tapLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_swipeUpLabel withOffset:30];
    
    // add the title labels above the phone and labels
    UILabel *titleLabel = [UILabel newAutoLayoutView];
    titleLabel.textColor = _swipeUpLabel.textColor;
    titleLabel.font = [UIFont gothamBookWithSize:15];
    titleLabel.numberOfLines = 0;
    titleLabel.attributedText = [@"TURN ON BLUETOOTH" rly_kernedStringWithKerning:4];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [phoneContainer addSubview:titleLabel];
    
    [titleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    UILabel *mattersMostLabel = [UILabel newAutoLayoutView];
    mattersMostLabel.numberOfLines = 0;
    mattersMostLabel.textAlignment = NSTextAlignmentCenter;
    mattersMostLabel.font = _swipeUpLabel.font;
    mattersMostLabel.textColor = _swipeUpLabel.textColor;
    mattersMostLabel.text = @"Ringly uses Bluetooth to notify you about the things that matter most.\n\nIt's easy to enable.";
    [phoneContainer addSubview:mattersMostLabel];
    
    [mattersMostLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:40];
    [mattersMostLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [mattersMostLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    [mattersMostLabel autoPinEdge:ALEdgeBottom
                           toEdge:ALEdgeTop
                           ofView:_fakePhoneView
                       withOffset:-40
                         relation:NSLayoutRelationLessThanOrEqual];
    [mattersMostLabel autoPinEdge:ALEdgeBottom
                           toEdge:ALEdgeTop
                           ofView:labelsContainer
                       withOffset:-40
                         relation:NSLayoutRelationLessThanOrEqual];
}

#pragma mark - View Lifecycle
-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // initialize layout properties for animation phase
    self.animationPhase = _animationPhase;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewIsVisible = YES;
    
    if (!_alreadyAnimating)
    {
        [self repeatedlyAnimate];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _viewIsVisible = NO;
    
    self.animationPhase = PoweredOffAnimationPhaseStart;
}

#pragma mark - Animations
-(void)setAnimationPhase:(PoweredOffAnimationPhase)animationPhase
{
    _animationPhase = animationPhase;

    // show fake swipe up touches
    if (animationPhase == PoweredOffAnimationPhaseSwipingUpFirst || animationPhase == PoweredOffAnimationPhaseSwipingUpSecond)
    {
        [self showFakeTouchForPhase:animationPhase];
    }

    // show fake tap
    if (animationPhase == PoweredOffAnimationPhaseFakeTap)
    {
        [self showFakeTapForPhase:animationPhase];
    }

    // update component visibility
    self.swipeUpLabel.alpha = _animationPhase >= PoweredOffAnimationPhaseSwipeUp ? 1 : 0;
    self.tapLabel.alpha = _animationPhase >= PoweredOffAnimationPhasePowerOn ? 1 : 0;
    self.fakePhoneView.bluetoothEnabled = _animationPhase >= PoweredOffAnimationPhasePoweredOn;

    // show/hide control center
    self.fakePhoneView.controlCenterUp = animationPhase >= PoweredOffAnimationPhaseSwipingUpSecond;
    [self.fakePhoneView layoutIfInWindowAndNeeded];
}

-(void)repeatedlyAnimate
{
    // don't allow multiple animations
    _alreadyAnimating = YES;
    
    PoweredOffAnimationPhase currentPhase = _animationPhase;
    PoweredOffAnimationPhase newPhase = currentPhase == PoweredOffAnimationPhaseDone
                                      ? PoweredOffAnimationPhaseStart
                                      : currentPhase + 1;
    
    PhaseProperties properties = PropertiesForPhase(newPhase);
    
    [UIView animateWithDuration:properties.animationTime animations:^{
        self.animationPhase = newPhase;
    }];
    
    
    __weak typeof(self) weakSelf = self;
    
    RLYDispatchAfterMain(properties.animationTime + properties.delayTime, ^{
        if (weakSelf.viewIsVisible)
        {
            [weakSelf repeatedlyAnimate];
        }
        else
        {
            weakSelf.alreadyAnimating = NO;
        }
    });
}

-(void)showFakeTouchForPhase:(PoweredOffAnimationPhase)phase
{
    __weak typeof(self) weakSelf = self;
    
    // make sure we're outside of the current animation block
    dispatch_async(dispatch_get_main_queue(), ^{
        // calculate frame for fake touch view
        CGRect screen = [weakSelf.fakePhoneView.screen convertRect:weakSelf.fakePhoneView.screen.bounds
                                                            toView:weakSelf.fakePhoneView];

        CGRect frame = CGRectMake(CGRectGetMidX(screen) - kFakeTouchViewSize.width / 2,
                                  CGRectGetMaxY(screen) + 2 /* offset to center with buttons */,
                                  kFakeTouchViewSize.width,
                                  kFakeTouchViewSize.height);
        
        // create a fake touch view
        FakeTouchView *touch = [[FakeTouchView alloc] initWithFrame:frame];
        touch.alpha = 0;
        [weakSelf.fakePhoneView addSubview:touch];
        
        // animate the fake touch upwards
        [UIView animateKeyframesWithDuration:PropertiesForPhase(phase).animationTime delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.1 animations:^{
                touch.alpha = 1;
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1.0 animations:^{
                touch.transform = CGAffineTransformMakeTranslation(0, -weakSelf.fakePhoneView.controlCenterHeight);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.9 relativeDuration:0.1 animations:^{
                touch.alpha = 0;
            }];
        } completion:^(BOOL finished) {
            [touch removeFromSuperview];
        }];
    });
}

-(void)showFakeTapForPhase:(PoweredOffAnimationPhase)phase
{
    __weak typeof(self) weakSelf = self;
    
    // make sure we're outside of the current animation block
    dispatch_async(dispatch_get_main_queue(), ^{
        // match the fake touch animation to the animation properties for this phase
        PhaseProperties properties = PropertiesForPhase(phase);
        
        [FakeTouchView fakeTouchCenteredOnPoint:weakSelf.fakePhoneView.bluetoothCenter
                                         ofView:weakSelf.fakePhoneView
                            animationInDuration:properties.animationTime
                                  dwellDuration:properties.delayTime
                           animationOutDuration:0.25];
    });
}

@end
