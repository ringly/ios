#import <RinglyKit/RinglyKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Colors

/**
 *  Enumerates the default colors of the Ringly LED.
 */
typedef NS_ENUM(NSInteger, DefaultColor)
{
    /**
     *  Disabled - no color shown on the LED.
     */
    DefaultColorNone = 0,
    
    /**
     *  Blue.
     */
    DefaultColorBlue = 1,
    
    /**
     *  Green.
     */
    DefaultColorGreen = 2,
    
    /**
     *  Yellow.
     */
    DefaultColorYellow = 3,
    
    /**
     *  Purple.
     */
    DefaultColorPurple = 4,
    
    /**
     *  Red.
     */
    DefaultColorRed = 5
};

#pragma mark - Colors - Indices
/**
 *  Returns a `DefaultColor` converted from an integer index.
 *
 *  @param index The index.
 */
RINGLYKIT_EXTERN DefaultColor DefaultColorFromIndex(NSUInteger index);

/**
 *  Returns an integer index converted from a `DefaultColor`.
 *
 *  @param DefaultColor The color.
 */
RINGLYKIT_EXTERN NSUInteger DefaultColorToIndex(DefaultColor DefaultColor);

#pragma mark - Colors - UI
/**
 *  Returns a string representation for a `DefaultColor`.
 *
 *  @param DefaultColor The color.
 */
RINGLYKIT_EXTERN NSString *DefaultColorToString(DefaultColor DefaultColor);

#pragma mark - Colors - Sequencing
/**
 *  Returns the color after the specified `DefaultColor`. Includes wrapping.
 *
 *  @param DefaultColor The color.
 */
RINGLYKIT_EXTERN DefaultColor DefaultColorAfter(DefaultColor DefaultColor);

/**
 *  Returns the color before the specified `DefaultColor`. Includes wrapping.
 *
 *  @param DefaultColor The color.
 */
RINGLYKIT_EXTERN DefaultColor DefaultColorBefore(DefaultColor DefaultColor);

#pragma mark - Color - Peripheral LED
/**
 *  Converts a `DefaultColor` to a `RLYColor`.
 *
 *  @param DefaultColor The color.
 */
RINGLYKIT_EXTERN RLYColor DefaultColorToLEDColor(DefaultColor DefaultColor);

NS_ASSUME_NONNULL_END
