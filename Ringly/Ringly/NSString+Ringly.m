#import <RinglyKit/RLYFunctions.h>
#import <RinglyExtensions/RinglyExtensions-Swift.h>
#import "NSString+Ringly.h"
#import "Ringly-Swift.h"

double const kNSStringRinglyDefaultKerning = 10;

@implementation NSString (Ringly)

#pragma mark - Attributed Kerning
-(NSAttributedString*)rly_kernedString
{
    return [self rly_kernedStringWithKerning:kNSStringRinglyDefaultKerning];
}

-(NSAttributedString*)rly_kernedStringWithKerning:(double)kerning
{
    NSDictionary *attributes = @{ NSKernAttributeName: @(kerning) };
    return [[NSAttributedString alloc] initWithString:self attributes:attributes];
}

-(NSAttributedString*)rly_kernedStringWithKerning:(double)kerning color:(UIColor*)color
{
    NSDictionary *attributes = @{ NSKernAttributeName: @(kerning),
                                  NSForegroundColorAttributeName: color };
    return [[NSAttributedString alloc] initWithString:self attributes:attributes];
}

#pragma mark - Names
-(NSString*)rly_firstName
{
    return [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]][0];
}

-(NSString*)rly_lastName
{
    NSArray *split = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (split.count > 1)
    {
        return [[split subarrayWithRange:NSMakeRange(1, split.count - 1)] componentsJoinedByString:@" "];
    }
    else
    {
        return nil;
    }
}

-(NSArray*)rly_firstAndLastName
{
    return @[self.rly_firstName ?: @"", self.rly_lastName ?: @""];
}

#pragma mark - DFU
+(NSDictionary*)rly_DFUAttributesWithFont:(UIFont*)font kerning:(CGFloat)kerning
{
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 3;
    
    return @{ NSKernAttributeName: @(kerning * font.pointSize / 1000),
              NSParagraphStyleAttributeName: style,
              NSForegroundColorAttributeName: [UIColor whiteColor],
              NSFontAttributeName: font };
}

-(NSAttributedString*)rly_DFUStringWithFont:(UIFont*)font kerning:(CGFloat)kerning
{
    NSDictionary *attributes = [NSString rly_DFUAttributesWithFont:font kerning:kerning];
    return [[NSAttributedString alloc] initWithString:self attributes:attributes];
}

+(NSDictionary*)rly_DFUTitleAttributesWithKerning:(CGFloat)kerning
{
    return [self rly_DFUAttributesWithFont:[UIFont gothamBoldWithSize:17] kerning:kerning];
}

-(NSAttributedString*)rly_DFUTitleStringWithKerning:(CGFloat)kerning
{
    return [[NSAttributedString alloc] initWithString:self
                                           attributes:[NSString rly_DFUTitleAttributesWithKerning:kerning]];
}

+(NSDictionary*)rly_DFUTitleAttributes
{
    return [NSString rly_DFUAttributesWithFont:[UIFont gothamBookWithSize:17] kerning:350];
}


-(NSAttributedString*)rly_DFUTitleString
{
    return [[NSAttributedString alloc] initWithString:self.uppercaseString
                                           attributes:[NSString rly_DFUTitleAttributes]];
}

+(NSDictionary*)rly_DFUWideTitleAttributes
{
    return [self rly_DFUTitleAttributesWithKerning:350];
}


-(NSAttributedString*)rly_DFUWideTitleString
{
    return [[NSAttributedString alloc] initWithString:self.uppercaseString
                                           attributes:[NSString rly_DFUWideTitleAttributes]];
}

+(NSDictionary*)rly_DFUBodyAttributes
{
    return [NSString rly_DFUAttributesWithFont:[UIFont gothamBookWithSize:15] kerning:160];
}

-(NSAttributedString*)rly_DFUBodyString
{
    return [[NSAttributedString alloc] initWithString:self attributes:[NSString rly_DFUBodyAttributes]];
}

@end

NSAttributedString *RLYAttributedString(NSString *string, NSDictionary *attributes, ...)
{
    va_list args;
    va_start(args, attributes);
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
    
    while (YES)
    {
        string = va_arg(args, NSString*);
        
        if (!string)
        {
            break;
        }
        
        attributes = va_arg(args, NSDictionary*);
        
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:attributes]];
    }
    
    va_end(args);
    
    return attr;
}
