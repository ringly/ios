import RinglyKit

/// Enumerates the possible states of a DFU controller.
public enum State
{
    // MARK: - Cases

    /// The user is instructed to place his or her peripheral in the charger.
    case peripheralInCharger(RLYPeripheralBatteryState?)

    /// The user is instructed to place his or her phone in the charger.
    case phoneInCharger(PhoneInChargerState)

    /**
     The controller is waiting for the user to perform "forget this device".

     - parameter initial: `true` if this is the initial "forget this device" step, `false` otherwise.
     */
    case waitingForForgetThisDevice(initial: Bool)

    /**
     The controller is waiting for the user to toggle Bluetooth power on the device.

     - parameter haveToggledOff: `true` if the user has toggled Bluetooth off, and the controller is waiting for
                                 Bluetooth to be toggled back on.
     */
    case waitingForBluetoothToggle(haveToggledOff: Bool)

    /// The controller is performing an action without determinate progress.
    case activity(ActivityReason)

    /// The controller is writing data to the peripheral.
    case writing(WriteProgress)

    /// The controller has completed the DFU process.
    case completed
}

// MARK: - Equatable
extension State: Equatable {}
public func ==(lhs: State, rhs: State) -> Bool
{
    switch (lhs, rhs)
    {
    // simple cases
    case (.completed, .completed): return true

    // cases with parameters
    case (.activity(let lhsReason), .activity(let rhsReason)):
        return lhsReason == rhsReason

    case (.phoneInCharger(let lhsState), .phoneInCharger(let rhsState)):
        return lhsState == rhsState

    case (.peripheralInCharger(let lhsState), .peripheralInCharger(let rhsState)):
        return lhsState == rhsState

    case (.waitingForForgetThisDevice(let lhsInitial), .waitingForForgetThisDevice(let rhsInitial)):
        return lhsInitial == rhsInitial

    case (.waitingForBluetoothToggle(let lhsHaveToggled), .waitingForBluetoothToggle(let rhsHaveToggled)):
        return lhsHaveToggled == rhsHaveToggled

    case (.writing(let lhsProgress), .writing(let rhsProgress)):
        return lhsProgress == rhsProgress

    default:
        return false
    }
}
