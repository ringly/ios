@import RinglyDFU;
@import RinglyKit;
#import <UIKit/UIKit.h>
#import "Ringly-Swift.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        RLYLogFunction = RLogBluetooth;
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
