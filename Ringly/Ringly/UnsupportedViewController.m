#import "UnsupportedViewController.h"
#import "Ringly-Swift.h"

@interface UnsupportedViewController ()

@end

@implementation UnsupportedViewController

-(void)loadView
{
    UIView *view = [UIView new];
    
    UIView *container = [UIView newAutoLayoutView];
    [view addSubview:container];
    
    [container autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:40];
    [container autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:40];
    [container autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    // add title label
    UILabel *title = [UILabel newAutoLayoutView];
    title.attributedText = @"Bluetooth Notice".uppercaseString.rly_kernedString;
    title.numberOfLines = 0;
    title.font = [UIFont gothamBookWithSize:13];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    [container addSubview:title];
    
    [title autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    // add message label
    UILabel *message = [UILabel newAutoLayoutView];
    NSString *device = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"iPhone" : @"iPad";
    message.text = [NSString stringWithFormat:@"Your %@ does not support the necessary Bluetooth technology to use Ringly.", device];
    message.numberOfLines = 0;
    message.font = [UIFont gothamBookWithSize:13];
    message.textColor = [UIColor whiteColor];
    message.textAlignment = NSTextAlignmentCenter;
    [container addSubview:message];
    
    [message autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:title withOffset:20];
    [message autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    self.view = view;
}

@end
