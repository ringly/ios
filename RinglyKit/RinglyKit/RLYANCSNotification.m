#import "RLYANCSNotification.h"

RLYANCSCategory RLYANCSCategoryFromNumericalString(NSString *numericalString)
{
    NSInteger value = numericalString.integerValue;
    return value < 12 && value >= 0 ? (RLYANCSCategory)value : RLYANCSCategoryOther;
}

#pragma mark -

@implementation RLYANCSNotification

#pragma mark - Initialization
-(instancetype)initWithVersion:(RLYANCSNotificationVersion)version
                      category:(RLYANCSCategory)category
         applicationIdentifier:(NSString*)applicationIdentifier
                         title:(NSString*)title
                          date:(NSDate*)date
                       message:(NSString*)message
                    flagsValue:(nullable RLYANCSNotificationFlagsValue*)flagsValue
{
    self = [super init];

    if (self)
    {
        _version = version;
        _category = category;
        _applicationIdentifier = applicationIdentifier;
        _title = title;
        _date = date;
        _message = message;
        _flagsValue = flagsValue;
    }

    return self;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(category = %d, application identifier = %@, title = %@, date = %@, message = %@, flags = %@)",
                                      _category,
                                      _applicationIdentifier,
                                      _title,
                                      _date,
                                      _message,
                                      _flagsValue];
}

@end
