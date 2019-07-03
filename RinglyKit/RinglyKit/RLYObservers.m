#import "RLYObservers.h"

@interface RLYObservableWrapper : NSObject

@property (nonatomic, weak) id observer;

@end

@implementation RLYObservableWrapper

-(NSUInteger)hash
{
    return [_observer hash];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RLYObservableWrapper class]])
    {
        return [_observer isEqual:[object observer]];
    }
    else
    {
        return NO;
    }
}

@end

@interface RLYObservers ()
{
@private
    NSMutableSet *_observers;
}

@end

@implementation RLYObservers

#pragma mark - Initialization
-(id)init
{
    self = [super init];
    
    if (self)
    {
        _observers = [NSMutableSet set];
    }
    
    return self;
}

#pragma mark - Observers
-(void)addObserver:(id)observer
{
    RLYObservableWrapper *wrapper = [RLYObservableWrapper new];
    wrapper.observer = observer;
    
    [_observers addObject:wrapper];
}

-(void)removeObserver:(id)observer
{
    [_observers filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RLYObservableWrapper *wrapper, NSDictionary *bindings) {
        return wrapper.observer && wrapper.observer != observer;
    }]];
}

-(void)enumerateObservers:(void(^)(id observer))block
{
    [_observers filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(RLYObservableWrapper *wrapper, NSDictionary *bindings) {
        if (wrapper.observer)
        {
            block(wrapper.observer);
        }
        
        return wrapper.observer != nil;
    }]];
}

@end
