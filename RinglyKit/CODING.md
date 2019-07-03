# Developing RinglyKit

## Formatting
- The class prefix is `RLY`. This should be included on all types, constants, and functions.
- Use four spaces for indentation.
- Align multiline message pass invocations to the colons - Xcode does this automatically.
- Avoid passing 120 characters columns, when possible.
- Use [Allman-style](https://en.wikipedia.org/wiki/Indent_style#Allman_style) brackets to make code block structure clearer, except for inline callback blocks, because it looks weird with those.

## Documentation
- Document everything!
- Install [VVDocumenter](https://github.com/onevcat/VVDocumenter-Xcode), and use it to provide documentation scaffolding.
- Use `#pragma mark - [Section]` to separate sections in header filess.

## Coding Requirements
- Do not embed strings for key paths, use the `RLY_KEYPATH` and `RLY_CLASS_KEYPATH` macros from `RLYDefines+Internal.h` instead. These macros provide compile-time verification of key paths.
- Mark functions and constants declared in headers with `RINGLYKIT_EXTERN`.
- For `NSError` configuration, provide a string constant named `RLY[Error Category]Domain` and an enumeration named `RLY[Error Category]Code`. Additionally, add a function to `RLYErrorFunctions.h`, and use it to create errors internally. This function should not be available to framework clients.
- Declare `struct` types with `typedef struct {} RLY[Name]`.
- Declare enumeration types with `NS_ENUM`.
- Declare bitflag types with `NS_OPTIONS`.
- Override `-description`, and provide a `[Type]ToString` function for C types.
- Boolean properties should be defined with `getter=is[Property]`, following Apple's style.

## Naming
- Name types used alongside a class and a *single* property with a combination of the two names. For example `RLYANCSNotification`'s `-version` property is of type `RLYANCSNotificationVersion`.
- Name types used alongside a class with *multiple* properties with the name of the class and a shared style from the property. `RLYPeripheralFeatureSupport` is used for the `RLYPeripheral` properties `chipVersionSupport`, `bootloaderVersionSupport`, etc.

## Patterns
### Use Objective-C
RinglyKit is written in Objective-C, to ensure maximum compatibility with other code bases. When and if a Swift rewrite happens, it will be intended to take full advantage of Swift, using value types, protocols as typeclasses, etc., so it will break compatibility with Objective-C.

### Divide Functionality into Protocols
Large classes like `RLYPeripheral` are difficult to mock, especially in Swift, where type boundaries are strictly enforced. To solve this, identify groups of functionality, and create a protocol. Then, have the larger class implement that functionality. The entire interface of `RLYPeripheral` is declared in protocols.

### Default to Internal
If functionality does not *need* to be exposed to clients, do not expose it. There's no reason to initialize a `RLYPeripheral` manually instead of retrieving an instance from a `RLYCentral` object, so this is not permitted.

### Prefer Immutability
When possible, classes should disallow mutation after initialization. An example of this is `RLYColorKeyframe` - values for all properties must be provided in the designated initializer, and all properties are `readonly`.

### Use “Instructions” for Mutability
When mutability is necessary, avoid using property setters. Instead, provide instruction messages. For example, given a `RLYPeripheral`:

    [peripheral readDeviceInformationCharacteristics:&error];

Or, given a `RLYCentral`:

    [central startDiscoveringPeripherals];

### Use Key-Value Observing for State
For state changes, provide properties that support key-value observing. All `@property` declarations in RinglyKit must be KVO-enabled. If a property is derived from a combination of other properties, provide a `+keyPathsForValuesAffecting…` implementation.

Ensure that value changes of observable properties are set via property setter (`self.property = value`) instead of direct ivar access (`_property = value`). Performing the latter will not correctly notify observers.

### Use Observer Protocols for Events
`RLYCentral` and `RLYPeripheral` define *observer protocols*, respectively, `RLYCentralObserver` and `RLYPeripheralObserver`. These are used for notifying clients of one-time events - for example, that a user tapped the peripheral a number of times. If clients should be notified about something that isn't a change in state, it should be added to an observer protocol.

All of an observer protocol's messages should be `@optional`.

## Annotations

### Mark Classes Final
Place the `RINGLYKIT_FINAL` macro in front of `@interface` declarations. This adds the `objc_subclassing_restricted` attribute to the class, with prohibits subclassing.

### Use Nullability Annotations
RinglyKit is designed for seamless integration with Swift code, so nullability annotations must be provided for all pointer type parameters and return values. Prefer `NS_ASSUME_NONNULL_BEGIN` and `NS_ASSUME_NONNULL_END`, and explicitly specify `nullable` if necessary.

### Use Collection Type Annotations
Specify the type of all `NSArray` and `NSDictionary` parameters and return values. This allows these types to be correctly imported in Swift code.

### Mark Invalid Initializers as Unavailable
If a class requires parameters for initialization, `-init` and `+new` should be marked `NS_UNAVAILABLE`.
