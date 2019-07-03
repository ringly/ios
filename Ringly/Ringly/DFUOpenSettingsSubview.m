#import "DFUOpenSettingsSubview.h"
#import "Ringly-Swift.h"

@interface DFUOpenSettingsSubview ()

@property (nonatomic, readonly, strong) NSLayoutConstraint *textLabelRight;

@end

@implementation DFUOpenSettingsSubview

+(CGFloat)fontSize
{
    return [UIScreen mainScreen].bounds.size.height > 568 ? 14 : 12;
}

+(NSDictionary*)stringAttributes
{
    return @{ NSKernAttributeName: @1.6 };
}

+(NSDictionary*)boldStringAttributes
{
    return @{ NSKernAttributeName: @1.6,
              NSFontAttributeName: [UIFont gothamBoldWithSize:[self fontSize]] };
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _contentArea = [UIView newAutoLayoutView];
        [self addSubview:_contentArea];
        
        _textLabel = [UILabel newAutoLayoutView];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont gothamBookWithSize:[self.class fontSize]];
        _textLabel.numberOfLines = 0;
        [self addSubview:_textLabel];
        
        // layout
        [_contentArea autoSetDimensionsToSize:CGSizeMake(99, 54)];
        [_contentArea autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeRight];
        
        [_textLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_contentArea withOffset:14];
        _textLabelRight = [_textLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [_textLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    }
    
    return self;
}

+(instancetype)viewWithText:(NSAttributedString*)text image:(UIImage*)image
{
    DFUOpenSettingsSubview *view = [self newAutoLayoutView];
    view.textLabel.attributedText = text;

    UIImageView *imageView = [UIImageView newAutoLayoutView];
    imageView.image = image;
    [view.contentArea addSubview:imageView];

    [imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];

    return view;
}

+(instancetype)openSettingsViewWithImage:(UIImage*)image
{
    NSAttributedString *text = RLYAttributedString(@"Go to the iPhone ".uppercaseString, [self stringAttributes],
                                                   @"Settings App".uppercaseString, [self boldStringAttributes],
                                                   nil);

    return [self viewWithText:text image:image];
}

+(instancetype)bluetoothView
{
    DFUOpenSettingsSubview *view = [self newAutoLayoutView];
    view.contentArea.backgroundColor = [UIColor whiteColor];
    view.contentArea.clipsToBounds = YES;
    
    view.textLabel.attributedText = RLYAttributedString(@"Tap ".uppercaseString, [self stringAttributes],
                                                        @"Bluetooth".uppercaseString, [self boldStringAttributes],
                                                        nil);
    
    UIView *container = [UIView newAutoLayoutView];
    [view.contentArea addSubview:container];
    
    CGFloat const leadingPadding = 8;
    CGFloat const middlePadding = 10;
    CGFloat const imageSize = 18;
    
    UIView*(^subview)(UIImage*, NSString*) = ^(UIImage *image, NSString *text) {
        UIView *view = [UIView newAutoLayoutView];
        
        UIImageView *imageView = [UIImageView newAutoLayoutView];
        imageView.image = image;
        [view addSubview:imageView];
        
        UILabel *label = [UILabel newAutoLayoutView];
        label.text = text;
        label.font = [UIFont systemFontOfSize:9];
        [view addSubview:label];
        
        [view autoSetDimension:ALDimensionHeight toSize:26];
        
        [imageView autoSetDimensionsToSize:CGSizeMake(imageSize, imageSize)];
        [imageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leadingPadding];
        
        [label autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
        [label autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:imageView withOffset:middlePadding];
        [label autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        return view;
    };
    
    UIView *wifi = subview([UIImage imageNamed:@"SettingsWifiIcon"], @"Wi-Fi");
    wifi.alpha = 0.5;
    [container addSubview:wifi];
    
    UIView *separator1 = [UIView newAutoLayoutView];
    separator1.backgroundColor = [UIColor colorWithRed:0.906 green:0.906 blue:0.914 alpha:1];
    [container addSubview:separator1];
    
    UIView *bluetooth = subview([UIImage imageNamed:@"SettingsBluetoothIcon"], @"Bluetooth");
    [container addSubview:bluetooth];
    
    UIView *separator2 = [UIView newAutoLayoutView];
    separator2.backgroundColor = [UIColor colorWithRed:0.906 green:0.906 blue:0.914 alpha:1];
    [container addSubview:separator2];
    
    UIView *cellular = subview([UIImage imageNamed:@"SettingsCellularIcon"], @"Cellular");
    cellular.alpha = 0.5;
    [container addSubview:cellular];
    
    [container autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [container autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [container autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [wifi autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    [separator1 autoSetDimension:ALDimensionHeight toSize:1];
    [separator1 autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leadingPadding + middlePadding + imageSize];
    [separator1 autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [separator1 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:wifi];
    
    [bluetooth autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [bluetooth autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [bluetooth autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:separator1];
    
    [separator2 autoSetDimension:ALDimensionHeight toSize:1];
    [separator2 autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leadingPadding + middlePadding + imageSize];
    [separator2 autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [separator2 autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:bluetooth];
    
    [cellular autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:separator2];
    [cellular autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    
    return view;
}

+(instancetype)findRinglyView
{
    DFUOpenSettingsSubview *view = [self newAutoLayoutView];
    view.contentArea.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1];
    
    if ([UIScreen mainScreen].bounds.size.height > 568)
    {
        view.textLabelRight.constant = 15;
    }
    
    NSDictionary *bold = [self boldStringAttributes];
    NSAttributedString *start = RLYAttributedString(@"Find your Ringly &\n".uppercaseString, [self stringAttributes],
                                                    @"tap the blue ".uppercaseString, bold,
                                                    nil);
    
    NSTextAttachment *attachment = [NSTextAttachment new];
    attachment.image = [UIImage imageNamed:@"Settings-i"];
    attachment.bounds = CGRectMake(0, -3, attachment.image.size.width, attachment.image.size.height);
    
    NSMutableAttributedString *mutable = [start mutableCopy];
    [mutable appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [mutable appendAttributedString:[[NSAttributedString alloc] initWithString:@" icon".uppercaseString attributes:bold]];
    
    view.textLabel.attributedText = mutable;
    
    UIView *container = [UIView newAutoLayoutView];
    [view.contentArea addSubview:container];
    
    UILabel *devices = [UILabel newAutoLayoutView];
    devices.text = @"MY DEVICES";
    devices.font = [UIFont systemFontOfSize:8];
    devices.textColor = [UIColor colorWithRed:0.404 green:0.404 blue:0.424 alpha:1];
    [container addSubview:devices];
    
    UIView *middle = [UIView newAutoLayoutView];
    middle.backgroundColor = [UIColor whiteColor];
    [container addSubview:middle];
    
    UILabel *label = [UILabel newAutoLayoutView];
    label.text = @"RINGLY";
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor blackColor];
    [middle addSubview:label];
    
    UIView *topLine = [UIView newAutoLayoutView];
    topLine.backgroundColor = [UIColor colorWithRed:0.855 green:0.855 blue:0.871 alpha:1];
    [container addSubview:topLine];
    
    UIView *bottomLine = [UIView newAutoLayoutView];
    bottomLine.backgroundColor = [UIColor colorWithRed:0.855 green:0.855 blue:0.871 alpha:1];
    [container addSubview:bottomLine];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    button.userInteractionEnabled = NO;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [middle addSubview:button];
    
    [container autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [container autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [container autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [devices autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [devices autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    
    [middle autoSetDimension:ALDimensionHeight toSize:26];
    [middle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:devices withOffset:5];
    [middle autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [middle autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [middle autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [topLine autoSetDimension:ALDimensionHeight toSize:1];
    [topLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [topLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [topLine autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:middle];
    
    [bottomLine autoSetDimension:ALDimensionHeight toSize:1];
    [bottomLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [bottomLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [bottomLine autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:middle];
    
    [label autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [label autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    
    [button autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [button autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:8];
    [button autoSetDimensionsToSize:CGSizeMake(13, 13)];
    
    return view;
}

+(instancetype)forgetThisDeviceView
{
    DFUOpenSettingsSubview *view = [self newAutoLayoutView];
    view.contentArea.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1];
    
    view.textLabel.attributedText = RLYAttributedString(@"Tap ".uppercaseString, [self stringAttributes],
                                                        @"Forget This\nDevice".uppercaseString, [self boldStringAttributes],
                                                        @", ", [self stringAttributes],
                                                        @"confirm".uppercaseString, [self boldStringAttributes],
                                                        @",\nand return to\nthe Ringly app.".uppercaseString, [self stringAttributes],
                                                        nil);
    
    UIView *middle = [UIView newAutoLayoutView];
    middle.backgroundColor = [UIColor whiteColor];
    [view.contentArea addSubview:middle];
    
    UILabel *label = [UILabel newAutoLayoutView];
    label.text = @"Forget This Device";
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor colorWithRed:0 green:0.459 blue:1 alpha:1];
    [middle addSubview:label];
    
    UIView *topLine = [UIView newAutoLayoutView];
    topLine.backgroundColor = [UIColor colorWithRed:0.855 green:0.855 blue:0.871 alpha:1];
    [view.contentArea addSubview:topLine];
    
    UIView *bottomLine = [UIView newAutoLayoutView];
    bottomLine.backgroundColor = [UIColor colorWithRed:0.855 green:0.855 blue:0.871 alpha:1];
    [view.contentArea addSubview:bottomLine];
    
    [middle autoSetDimension:ALDimensionHeight toSize:26];
    [middle autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [middle autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [middle autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    [topLine autoSetDimension:ALDimensionHeight toSize:1];
    [topLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [topLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [topLine autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:middle];
    
    [bottomLine autoSetDimension:ALDimensionHeight toSize:1];
    [bottomLine autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [bottomLine autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [bottomLine autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:middle];
    
    [label autoCenterInSuperview];
    
    return view;
}

@end
