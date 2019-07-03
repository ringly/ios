#import "DefaultColor.h"

#pragma mark - Colors
DefaultColor DefaultColorFromIndex(NSUInteger index)
{
    return (DefaultColor)index;
}

NSUInteger DefaultColorToIndex(DefaultColor DefaultColor)
{
    return (NSUInteger)DefaultColor;
}

NSString *DefaultColorToString(DefaultColor DefaultColor)
{
    switch (DefaultColor)
    {
        case DefaultColorNone:
            return @"None";
        case DefaultColorBlue:
            return @"Blue";
        case DefaultColorGreen:
            return @"Green";
        case DefaultColorPurple:
            return @"Purple";
        case DefaultColorRed:
            return @"Red";
        case DefaultColorYellow:
            return @"Yellow";
    }
}

DefaultColor DefaultColorAfter(DefaultColor DefaultColor)
{
    return DefaultColor == DefaultColorRed ? DefaultColorNone : DefaultColor + 1;
}

DefaultColor DefaultColorBefore(DefaultColor DefaultColor)
{
    return DefaultColor == DefaultColorNone ? DefaultColorRed : DefaultColor - 1;
}

#pragma mark - Color - Peripheral LED
RLYColor DefaultColorToLEDColor(DefaultColor color)
{
    switch (color)
    {
        case DefaultColorNone:
            return RLYColorMake(0, 0, 0);
        case DefaultColorBlue:
            return RLYColorMake(0, 0, 255);
        case DefaultColorGreen:
            return RLYColorMake(0, 255, 0);
        case DefaultColorPurple:
            return RLYColorMake(191, 0, 255);
        case DefaultColorRed:
            return RLYColorMake(255, 0, 0);
        case DefaultColorYellow:
            return RLYColorMake(35, 155, 0);
    }
}
