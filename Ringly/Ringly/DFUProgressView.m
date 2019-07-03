#import "DFUProgressView.h"
#import "Ringly-Swift.h"

@interface DFUProgressView ()

@property (nonatomic, readonly, strong) RingProgressIndicator *progressIndicator;
@property (nonatomic, readonly, strong) UILabel *progressLabel;

@end

@implementation DFUProgressView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        // add subviews
        _progressLabel = [UILabel newAutoLayoutView];
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.font = [UIFont gothamLightWithSize:30];
        [self addSubview:_progressLabel];
        [_progressLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_progressLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:140];

        _progressIndicator = [RingProgressIndicator newAutoLayoutView];
        [self addSubview:_progressIndicator];
        [_progressIndicator autoPinEdgesToSuperviewEdges];

        // layout
        [self autoSetDimensionsToSize:_progressIndicator.idealSize];
    }

    return self;
}

-(void)setProgress:(NSInteger)progress
{
    _progress = progress;

    [UIView animateWithDuration:0.4 animations:^{
        self.progressIndicator.progress = (CGFloat)progress / 100.0;
        [self.progressIndicator layoutIfInWindowAndNeeded];
    }];

    [UIView transitionWithView:_progressLabel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        NSString *text = [NSString stringWithFormat:@"%d%%", (int)progress];
        NSDictionary *attrs = @{ NSKernAttributeName: @1.6 };
        self.progressLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attrs];
    } completion:nil];
}

@end
