#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Ringly)

/**
 *  Returns a copy of the dictionary with `[NSNull null]` removed recursively.
 */
-(instancetype)rly_dictionaryByRemovingNSNull;

@end

NS_ASSUME_NONNULL_END
