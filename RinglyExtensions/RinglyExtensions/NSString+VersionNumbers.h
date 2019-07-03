@import UIKit;

@interface NSString (VersionNumbers)

#pragma mark - Version Numbers

/**
 *  Returns the components of a version number string.
 */
-(NSArray*)rly_versionNumberComponents;

/**
 *  Compares two version number strings.
 *
 *  @param string The other version number string.
 */
-(NSComparisonResult)rly_compareVersionNumbers:(NSString *)string;

/**
 *  Replaces all version number separators in the string with `separator`.
 *
 *  @param separator The separator to use.
 */
-(NSString*)rly_versionNumberWithSeparator:(NSString*)separator;

/// True if the receiver is greater than `start` and less than `end`.
-(BOOL)rly_versionNumberIsAfter:(NSString*)start andBefore:(NSString*)end NS_SWIFT_NAME(versionNumberIs(after:before:));

/// True if the receiver is greater than `start`.
-(BOOL)rly_versionNumberIs:(NSString*)start NS_SWIFT_NAME(versionNumberIsAfter(after:));

@end
