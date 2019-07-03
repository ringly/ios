@import UIKit;

FOUNDATION_EXTERN double const kNSStringRinglyDefaultKerning;

FOUNDATION_EXTERN NSAttributedString *RLYAttributedString(NSString *string, NSDictionary *attributes, ...) NS_REQUIRES_NIL_TERMINATION;

@interface NSString (Ringly)

#pragma mark - Attributed Kerning
@property (nonatomic, readonly, copy) NSAttributedString *rly_kernedString;
-(NSAttributedString*)rly_kernedStringWithKerning:(double)kerning;
-(NSAttributedString*)rly_kernedStringWithKerning:(double)kerning color:(UIColor*)color;

#pragma mark - Names
/** @name Names */

/**
 *  Returns the "first name" of the string - all of the content before a whitespace character.
 */
@property (nonatomic, readonly) NSString *rly_firstName;

/**
 *  Returns the "last name" of the string - all of the content after the first name, with multiple whitespace characters
 *  in sequence being replaced with a signal space character, or `nil` if no whitespace characters are present.
 */
@property (nonatomic, readonly) NSString *rly_lastName;

/**
 *  Returns an array of the first name and last name. If the last name is `nil`, it will be replaced with an empty
 *  string.
 */
@property (nonatomic, readonly) NSArray *rly_firstAndLastName;

#pragma mark - DFU
/** @name DFU */
+(NSDictionary*)rly_DFUAttributesWithFont:(UIFont*)font kerning:(CGFloat)kerning;
-(NSAttributedString*)rly_DFUStringWithFont:(UIFont*)font kerning:(CGFloat)kerning;

+(NSDictionary*)rly_DFUTitleAttributesWithKerning:(CGFloat)kerning;
-(NSAttributedString*)rly_DFUTitleStringWithKerning:(CGFloat)kerning;

+(NSDictionary*)rly_DFUTitleAttributes;
-(NSAttributedString*)rly_DFUTitleString;

+(NSDictionary*)rly_DFUWideTitleAttributes;
-(NSAttributedString*)rly_DFUWideTitleString;

+(NSDictionary*)rly_DFUBodyAttributes;
-(NSAttributedString*)rly_DFUBodyString;

@end
