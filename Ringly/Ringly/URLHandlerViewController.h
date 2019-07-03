#import <UIKit/UIKit.h>

@protocol URLHandler <NSObject>

-(BOOL)handleOpenURL:(NSURL*)URL sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end

@interface URLHandlerViewController : UIViewController <URLHandler>

@end
