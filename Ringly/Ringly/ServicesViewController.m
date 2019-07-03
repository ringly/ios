#import "ServicesViewController.h"

@implementation ServicesViewController

#pragma mark - Initialization
-(instancetype)initWithServices:(Services*)services
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
    {
        _services = services;
    }
    
    return self;
}

@end
