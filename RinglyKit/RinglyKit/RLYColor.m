#import "RLYColor.h"

#pragma mark - LED Colors
RLYColor RLYColorMake(RLYColorComponent red, RLYColorComponent green, RLYColorComponent blue)
{
    RLYColor color = {
        .red = red,
        .green = green,
        .blue = blue
    };
    
    return color;
}

NSString *RLYColorToString(RLYColor color)
{
    if (RLYColorEqualToColor(color, RLYColorNone))
    {
        return @"none";
    }
    else
    {
        return [NSString stringWithFormat:@"(red: %d, green: %d, blue: %d)",
                (int)color.red, (int)color.green, (int)color.blue];
    }
}

BOOL RLYColorEqualToColor(RLYColor left, RLYColor right)
{
    return left.red == right.red && left.green == right.green && left.blue == right.blue;
}

RLYColor const RLYColorNone = { .red = 0, .green = 0, .blue = 0 };
