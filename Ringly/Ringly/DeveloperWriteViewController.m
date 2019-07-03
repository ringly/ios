

#if FUTURE || DEBUG
#import <DOKeyboard/DOKeyboard.h>
#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYPeripheral+Internal.h>
#import "DeveloperWriteViewController.h"
#import "Ringly-Swift.h"

@interface DeveloperWriteViewController () <UITextFieldDelegate>

@property (nonatomic, readonly, strong) UITextField *field;

@end

@implementation DeveloperWriteViewController

#pragma mark - Initialization
-(instancetype)initWithServices:(Services * __nonnull)services
                     peripheral:(RLYPeripheral * __nonnull)peripheral
                 characteristic:(CBCharacteristic * __nonnull)characteristic
{
    self = [super initWithServices:services];
    
    if (self)
    {
        _peripheral = peripheral;
        _characteristic = characteristic;

        self.title = [RLYPeripheral descriptionForCharacteristicWithUUID:_characteristic.UUID];

        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                          target:self
                                                          action:@selector(dismissAction:)];
    }
    
    return self;
}

#pragma mark - View Loading
-(void)loadView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.view = view;
    
    _field = [UITextField newAutoLayoutView];
    _field.delegate = self;
    _field.backgroundColor = [UIColor whiteColor];

    DOKeyboard *keyboard = [DOKeyboard keyboardWithType:DOKeyboardTypeHex];
    keyboard.input = _field;
    _field.inputView = keyboard;
    
    [view addSubview:_field];
    
    [_field autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [_field autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20];
    [_field autoPinToTopLayoutGuideOfViewController:self withInset:20];
}

#pragma mark - View Lifecycle
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_field becomeFirstResponder];
}

#pragma mark - Text Field Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *text = textField.text;
    
    if (text.length % 2 == 0)
    {
        NSUInteger length = text.length / 2;
        uint8_t bytes[length];
        
        for (int i = 0; i < length; i++)
        {
            NSString *substring = [text substringWithRange:NSMakeRange(i * 2, 2)];
            NSScanner *scanner = [NSScanner scannerWithString:substring];
            unsigned int value;
            
            if ([scanner scanHexInt:&value])
            {
                bytes[i] = (uint8_t)value;
            }
            else
            {
                [self presentAlertWithTitle:@"Error scanning" message:substring];
                return NO;
            }
        }
        
        NSData *data = [[NSData alloc] initWithBytes:bytes length:length];
        [_peripheral.CBPeripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        [self presentAlertWithTitle:@"Error" message:@"Must be valid hex, multiple of two"];
    }
    
    return NO;
}

-(void)dismissAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
