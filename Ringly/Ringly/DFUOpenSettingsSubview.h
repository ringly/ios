#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DFUOpenSettingsSubview : UIView

@property (nonatomic, readonly, strong) UIView *contentArea;
@property (nonatomic, readonly, strong) UILabel *textLabel;

+(instancetype)viewWithText:(NSAttributedString*)text image:(nullable UIImage*)image NS_SWIFT_NAME(view(text:image:));
+(instancetype)openSettingsViewWithImage:(nullable UIImage*)image;
+(instancetype)bluetoothView;
+(instancetype)findRinglyView;
+(instancetype)forgetThisDeviceView;

@end

NS_ASSUME_NONNULL_END
