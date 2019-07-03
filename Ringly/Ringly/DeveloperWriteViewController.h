#import "TopbarViewController.h"

#if FUTURE || DEBUG

NS_ASSUME_NONNULL_BEGIN

@interface DeveloperWriteViewController : ServicesViewController

-(instancetype)initWithServices:(Services *)services
                     peripheral:(RLYPeripheral*)peripheral
                 characteristic:(CBCharacteristic*)characteristic;

@property (nonatomic, readonly, strong) RLYPeripheral *peripheral;
@property (nonatomic, readonly, strong) CBCharacteristic *characteristic;

@end

NS_ASSUME_NONNULL_END

#endif
