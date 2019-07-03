# RinglyKit
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

RinglyKit is a framework for integrating with [Ringly](http://ringly.com) Bluetooth peripherals.

## Concepts
### Centrals
A `RLYCentral` instance is the primary gateway to RinglyKit. This class is the analog of `CBCentralManager` in Core Bluetooth, and uses an instance of that internally. `RLYCentral` handles Bluetooth state, and provides access to peripheral objects via discovery and retrieving connected or specific peripherals.

Generally, a client of RinglyKit should only need one central instance. `RLYCentral` will theoretically work with an arbitrary number of instances, but the underlying `CBCentralManager` may not.

### Peripherals
Instances of the `RLYPeripheral` class are associated with a specific Ringly peripheral. The class provides information about the peripheral's state, and an interface to make changes to the peripheral's state, or make the peripheral perform other actions.

### Observation
`RLYCentral` and `RLYPeripheral` are designed to be consumed by an arbitrary number of observers. There are two methods of observation:

- For state, key-value observing: standard Cocoa KVO can be used on any `@property` of `RLYCentral` and `RLYPeripheral`.
- For events, protocol-based observers: `RLYCentral` and `RLYPeripheral` each provide an associated “observer” protocol, `RLYCentralObserver` and `RLYPeripheralObserver` respectively. Objects implementing these protocols will receive messages about events, once added to an observable object with the `-addObserver:` message.

### Commands
A command value is used when instructing a peripheral to perform an action, such as lighting up or vibrating. Commands implement `RLYCommand`, and each includes a high-level interface, so clients do not need to concern themselves with the byte array representations actually sent to peripherals. 

## Swift
RinglyKit is written in Objective-C, but it is designed for easy integration with Swift. All pointer types are annotated for nullability, and collections are annotated with generic types. Additionally, types are annotated with `NS_UNAVAILABLE` when `NSObject`'s `-init` should not be used, preventing its use in Swift. Therefore, most the the API integrates seamlessly.

However, while the protocol-based observing is reasonably usable in Swift, RinglyKit's heavy use of key-value observing can be awkward to use, as much of Swift's type-safety is discarded when working with KVO.

To work around this limitation, the ReactiveRinglyKit framework bridges RinglyKit to [ReactiveSwift](https://github.com/reactivecocoa/reactiveswift), and integrates well with Swift. The `RLYCentral` and `RLYPeripheral` classes are extended to provide Swift-compatible interfaces, using ReactiveSwift for observation instead of KVO.

## Documentation
If necessary, install `jazzy`:

    gem install jazzy
   
Then run:

    make docs

To generate HTML documentation in the `Documentation` subdirectory.
