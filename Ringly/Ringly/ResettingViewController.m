#import "Ringly-Swift.h"
#import "ResettingViewController.h"

@implementation ResettingViewController

-(void)loadView
{
    UIView *view = [UIView new];
    
    UIView *container = [UIView newAutoLayoutView];
    [view addSubview:container];
    
    [container autoCenterInSuperview];
    
    // add title label
    DiamondActivityIndicator *activity = [DiamondActivityIndicator newAutoLayoutView];
    [activity constrainToDefaultSize];
    [container addSubview:activity];
    
    [activity autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [activity autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [activity autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [activity autoPinEdgeToSuperviewEdge:ALEdgeTop];
    
    // add message label
    UILabel *message = [UILabel newAutoLayoutView];
    message.text = @"Bluetooth is resetting";
    message.numberOfLines = 0;
    message.font = [UIFont gothamBookWithSize:13];
    message.textColor = [UIColor whiteColor];
    message.textAlignment = NSTextAlignmentCenter;
    [container addSubview:message];
    
    [message autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:activity withOffset:20];
    [message autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [message autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [message autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [message autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    self.view = view;
}

@end
