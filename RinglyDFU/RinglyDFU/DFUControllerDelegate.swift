import Foundation
import RinglyKit

public protocol DFUControllerDelegate
{
    // MARK: - Interaction with Peripherals

    /**
     Instructs the delegate whether or not it may interact with the peripheral with the specified identifier.

     - parameter allowInteraction: Whether or not interaction should be allowed.
     - parameter identifier:       The peripheral identifier to start or stop interacting with.
     */
    func DFUController(allowInteraction: Bool,
                       withPeripheralWithIdentifier identifier: UUID)

    // MARK: - “Forget This Device”

    /**
     Instructs the delegate to perform a DFU forget-this-device if the peripheral is forgotten.

     - parameter peripheral:    The peripheral to perform DFU forget-this-device on.
     - parameter update:        A callback function to call when the peripheral is forgotten.
     */
    func DFUController(startPerformingDFUForgetThisDeviceOnPeripheral peripheral: RLYPeripheral,
                       update: @escaping (ForgetThisDeviceUpdate) -> ())

    /**
     Instructs the delegate not to perform a DFU forget-this-device if the peripheral is forgotten anymore.

     - parameter peripheral:    The peripheral to stop performing DFU forget-this-device on.
     */
    func DFUController(stopPerformingDFUForgetThisDeviceOnPeripheral peripheral: RLYPeripheral)
}

public enum ForgetThisDeviceUpdate
{
    case started
    case completed
}
