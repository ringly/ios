#import "ServicesViewController.h"

@class TopbarView;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN CGFloat const TopbarViewControllerTopbarHeight;

@interface TopbarViewController : ServicesViewController

#pragma mark - Topbar View
/**
 *  The topbar view for this view controller.
 */
@property (nonatomic, readonly, strong) TopbarView *topbarView;

#pragma mark - Content
/**
 *  The view to place additional content inside.
 */
@property (nonatomic, readonly, strong) UIView *contentView;

/**
 *  Allows subclasses to provide a custom content view.
 */
-(UIView*)loadContentView;

#pragma mark - Actions
/**
 *  Action message sent when the navigation button is tapped. The default implementation notifies the view controller's
 *  `navigationDelegate` that navigation has been requested.
 */
-(void)navigationButtonAction:(nullable id)sender;

/**
 *  Action message sent when the action button is tapped. There is no need to call the `super` implementation in
 *  overrides.
 */
-(void)actionButtonAction:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
