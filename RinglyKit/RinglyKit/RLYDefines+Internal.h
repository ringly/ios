/**
 *  A compile-time-verified macro for building a key path for instances of a class.
 *
 *  @param CLASS   The class.
 *  @param KEYPATH The key path.
 */
#define RLY_CLASS_KEYPATH(CLASS, KEYPATH) (RLY_KEYPATH(((CLASS*)nil), KEYPATH))

/**
 *  A compile-time-verified macro for building a key path for an object.
 *
 *  @param OBJECT  The object.
 *  @param KEYPATH The key path.
 */
#define RLY_KEYPATH(OBJECT, KEYPATH) (((void)(NO && ((void)OBJECT.KEYPATH, NO)), @#KEYPATH))

/**
 *  Sets the error pointer `error` and returns a failure value.
 *
 *  @param ERROR_OBJECT The error object.
 *  @param RETURN_VALUE The return value.
 */
#define RLY_SET_ERROR_AND_RETURN(ERROR_OBJECT, RETURN_VALUE) \
    do {\
        if (error != nil) { *error = ERROR_OBJECT; } return RETURN_VALUE;\
    } while (NO)
