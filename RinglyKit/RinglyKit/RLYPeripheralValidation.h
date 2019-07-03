#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The possible validation states of a peripheral.
 */
typedef NS_ENUM(NSInteger, RLYPeripheralValidationState)
{
    /**
     *  The peripheral has been validated.
     */
    RLYPeripheralValidationStateValidated,

    /**
     *  The peripheral's services have not been found.
     */
    RLYPeripheralValidationStateMissingServices,

    /**
     *  The peripheral's Ringly characteristics have not been found.
     */
    RLYPeripheralValidationStateMissingRinglyCharacteristics,

    /**
     *  The peripheral's device information characteristics have not been found.
     */
    RLYPeripheralValidationStateMissingDeviceInformationCharacteristics,

    /**
     *  The peripheral's battery characteristics have not been found.
     */
    RLYPeripheralValidationStateMissingBatteryCharacteristics,

    /**
     *  The peripheral has an activity tracking service, but its characteristics have not been found.
     */
    RLYPeripheralValidationStateMissingActivityTrackingCharacteristics,

    /**
     *  The peripheral is waiting for notification states to be confirmed.
     */
    RLYPeripheralValidationStateWaitingForNotificationStateConformation,

    /**
     *  The peripheral has validation errors.
     */
    RLYPeripheralValidationStateHasValidationErrors
};


/**
 Returns a string representation of the validation state.

 @param validationState The validation state.
 */
RINGLYKIT_EXTERN NSString* RLYPeripheralValidationStateToString(RLYPeripheralValidationState validationState);

/**
 *  Contains properties describing the validation state of the peripheral.
 */
@protocol RLYPeripheralValidation <NSObject>

#pragma mark - State

/**
 *  The validation state of the peripheral.
 */
@property (nonatomic, readonly) RLYPeripheralValidationState validationState;

/**
 *  `YES` if the peripheral has bee validated, otherwise `NO`.
 *
 *  A peripheral is considered validated when all of the required Bluetooth information (services and characteristics)
 *  have been loaded.
 */
@property (nonatomic, readonly, getter=isValidated) BOOL validated;

/**
 *  `YES` if the peripheral is being validated.
 */
@property (nonatomic, readonly, getter=isWaitingForCharacteristics) BOOL waitingForCharacteristics;


#pragma mark - Errors

/**
 *  Any errors that occured while validating the peripheral. This value will be `nil` if 
 */
@property (nullable, nonatomic, readonly, strong) NSArray<NSError*> *validationErrors;

@end

NS_ASSUME_NONNULL_END
