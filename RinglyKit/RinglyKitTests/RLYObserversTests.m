#import <RinglyKit/RinglyKit.h>
#import <RinglyKit/RLYObservers.h>
#import <XCTest/XCTest.h>

@interface RLYObserversTests : XCTestCase

@end

@implementation RLYObserversTests

-(void)testAdditionAndRemoval
{
    RLYObservers *observers = [RLYObservers new];
    
    NSObject *observer = [NSObject new];
    [observers addObserver:observer];
    
    {
        __block NSUInteger count = 0;
        [observers enumerateObservers:^(id observer) {
            count++;
        }];
        
        XCTAssertEqual(count, (NSUInteger)1);
    }
    
    [observers removeObserver:observer];
    
    {
        __block NSUInteger count = 0;
        [observers enumerateObservers:^(id observer) {
            count++;
        }];
        
        XCTAssertEqual(count, (NSUInteger)0);
    }
}

-(void)testWeakReferences
{
    RLYObservers *observers = [RLYObservers new];
    
    NSObject *observer = [NSObject new];
    [observers addObserver:observer];
    observer = nil;
    
    __block NSUInteger count = 0;
    [observers enumerateObservers:^(id observer) {
        count++;
    }];
    
    XCTAssertEqual(count, (NSUInteger)0);
}

-(void)testUniqueness
{
    RLYObservers *observers = [RLYObservers new];
    
    NSObject *observer = [NSObject new];
    [observers addObserver:observer];
    [observers addObserver:observer];
    
    __block NSUInteger count = 0;
    [observers enumerateObservers:^(id observer) {
        count++;
    }];
    
    XCTAssertEqual(count, (NSUInteger)1);
}

@end
