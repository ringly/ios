#import "DFUFakePhoneView.h"

@interface DFUToggleBluetoothFakePhoneView : DFUFakePhoneView

@property (nonatomic, getter=isControlCenterUp) BOOL controlCenterUp;
@property (nonatomic, getter=isBluetoothEnabled) BOOL bluetoothEnabled;

-(CGPoint)bluetoothCenter;
-(CGFloat)controlCenterHeight;

@end
