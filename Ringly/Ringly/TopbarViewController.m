#import <PureLayout/PureLayout.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "Ringly-Swift.h"
#import "TopbarViewController.h"

CGFloat const TopbarViewControllerTopbarHeight = 66;

@interface TopbarViewController ()
{
@private
    TopbarView *_topbarView;
}

@end

@implementation TopbarViewController

#pragma mark - View Controller
-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - View Loading
-(void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view = view;
    
    // topbar view
    _topbarView = [TopbarView newAutoLayoutView];
    _topbarView.title = self.title;
    [view addSubview:_topbarView];
    
    // status bar blocker
    UIView *statusBarBlocker = [UIView newAutoLayoutView];
    statusBarBlocker.backgroundColor = _topbarView.backgroundColor;
    [view addSubview:statusBarBlocker];
    
    // content view
    _contentView = [self loadContentView];
    [view addSubview:_contentView];
    
    // layout
    [_topbarView autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [_topbarView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_topbarView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_topbarView autoSetDimension:ALDimensionHeight toSize:TopbarViewControllerTopbarHeight];
    
    [statusBarBlocker autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [statusBarBlocker autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_topbarView];
    
    [_contentView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topbarView];
    [_contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    // actions
    [_topbarView.leadingControl addTarget:self
                                   action:@selector(navigationButtonAction:)
                         forControlEvents:UIControlEventTouchUpInside];
    [_topbarView.trailingControl addTarget:self
                                    action:@selector(actionButtonAction:)
                          forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Content View
-(UIView*)loadContentView
{
    return [UIView newAutoLayoutView];
}

#pragma mark - Topbar View
-(TopbarView*)topbarView
{
    if (!_topbarView)
    {
        [self view];
    }
    
    return _topbarView;
}

#pragma mark - Actions
-(void)navigationButtonAction:(id)sender {}

-(void)actionButtonAction:(id)sender {}

#pragma mark - Title
-(void)setTitle:(NSString *)title
{
    [super setTitle:title];
    _topbarView.title = title;
}

@end
