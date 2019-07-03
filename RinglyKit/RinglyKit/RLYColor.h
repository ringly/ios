#import <Foundation/Foundation.h>
#import "RLYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// The type of each color component, an eight-bit unsigned integer.
typedef uint8_t RLYColorComponent;

/**
 *  Represents a color, as displayed on the peripheral's LED.
 */
typedef struct
{
    /**
     *  The red component.
     */
    RLYColorComponent red;
    
    /**
     *  The green component.
     */
    RLYColorComponent green;
    
    /**
     *  The blue component.
     */
    RLYColorComponent blue;
} RLYColor;

/**
 *  Creates a `RLYColor`.
 *
 *  @param red   The red component.
 *  @param green The green component.
 *  @param blue  The blue component.
 */
RINGLYKIT_EXTERN RLYColor RLYColorMake(RLYColorComponent red, RLYColorComponent green, RLYColorComponent blue);

/**
 *  Converts a color to a string representation.
 *
 *  @param color The color.
 */
RINGLYKIT_EXTERN NSString *RLYColorToString(RLYColor color);

/**
 *  Returns `YES` if the two colors are equal.
 *
 *  @param left  The left color.
 *  @param right The right color.
 */
RINGLYKIT_EXTERN BOOL RLYColorEqualToColor(RLYColor left, RLYColor right);

/**
 *  The "disabled" color (all `0` components).
 */
RINGLYKIT_EXTERN RLYColor const RLYColorNone;

NS_ASSUME_NONNULL_END
