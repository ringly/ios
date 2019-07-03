#import "Ringly-Swift.h"
#import "LegalViewController.h"

@interface LegalViewController ()

@end

@implementation LegalViewController

-(void)loadView
{
    [super loadView];
    
    UIWebView *webView = [UIWebView newAutoLayoutView];
    webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    [self.contentView addSubview:webView];
    [webView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    NSString *file = [[NSBundle mainBundle] pathForResource:@"Legal" ofType:@"html"];
    NSString *string = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:string baseURL:nil];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Legal";
    [self.topbarView.trailingControl setText:@"Done"];
}

-(void)actionButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
