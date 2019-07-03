

@class Services;
#import "URLHandlerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServicesViewController : URLHandlerViewController

#pragma mark - Initialization

/// This initializer is unavailable.
-(instancetype)init NS_UNAVAILABLE;

/// This initializer is unavailable.
-(instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// This initializer is unavailable.
-(instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 *  Initializes a `ServicesViewController`.
 *
 *  @param services The services object for this view controller.
 */
-(instancetype)initWithServices:(Services*)services NS_DESIGNATED_INITIALIZER;

#pragma mark - Services

/**
 *  The services object for this view controller. The value of this property will not change, although the individual
 *  services contained may.
 */
@property (nonatomic, readonly, strong) Services *services;

@end

NS_ASSUME_NONNULL_END
