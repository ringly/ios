import ReactiveSwift
import Result
import RinglyKit

extension Reactive where Base: RLYPeripheralDeviceInformation, Base: NSObject
{
    // MARK: - Peripheral Information
    
    /// Returns a signal producer for the peripheral's `identifier` property.
    public var identifier: SignalProducer<UUID, NoError>
    {
        return producerFor(keyPath: "identifier").skipNil()
    }
    
    /// Returns a signal producer for the peripheral's `name` property.
    public var name: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "name")
    }
    
    /// Returns a signal producer for the peripheral's `shortName` property.
    public var shortName: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "shortName")
    }
    
    /// Returns a signal producer for the peripheral's `lastFourMAC` property.
    public var lastFourMAC: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "lastFourMAC")
    }
    
    /// Returns a signal producer for the peripheral's `MACAddressSupport` property.
    public var MACAddressSupport: SignalProducer<RLYPeripheralFeatureSupport, NoError>
    {
        return producerFor(keyPath: "MACAddressSupport", defaultValue: RLYPeripheralFeatureSupport.undetermined.rawValue)
            .map({ value in RLYPeripheralFeatureSupport(rawValue: value)! })
    }
    
    /// Returns a signal producer for the peripheral's `MACAddress` property.
    public var MACAddress: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "MACAddress")
    }
    
    /// Returns a signal producer for the peripheral's `applicationVersion` property.
    public var applicationVersion: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "applicationVersion")
    }

    /// Returns a signal producer for the peripheral's `softdeviceVersionSupport` property.
    public var softdeviceVersionSupport: SignalProducer<RLYPeripheralFeatureSupport, NoError>
    {
        return producerFor(keyPath: "softdeviceVersionSupport", defaultValue: RLYPeripheralFeatureSupport.undetermined.rawValue)
            .map({ value in RLYPeripheralFeatureSupport(rawValue: value)! })
    }
    
    /// Returns a signal producer for the peripheral's `softdeviceVersion` property.
    public var softdeviceVersion: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "softdeviceVersion")
    }
    
    /// Returns a signal producer for the peripheral's `hardwareVersion` property.
    public var hardwareVersion: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "hardwareVersion")
    }

    /// Returns a signal producer for the peripheral's `knownHardwareVersion` property.
    public var knownHardwareVersionProducer: SignalProducer<RLYKnownHardwareVersion?, NoError>
    {
        return producerFor(keyPath: "knownHardwareVersion").map({ (value: RLYKnownHardwareVersionValue?) in
            value?.value
        })
    }
    
    /// Returns a signal producer for the peripheral's `chipVersion` property.
    public var chipVersion: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "chipVersion")
    }
    
    /// Returns a signal producer for the peripheral's `bootloaderVersionSupport` property.
    public var bootloaderVersionSupport: SignalProducer<RLYPeripheralFeatureSupport, NoError>
    {
        return producerFor(keyPath: "bootloaderVersionSupport", defaultValue: RLYPeripheralFeatureSupport.undetermined.rawValue)
            .map({ value in RLYPeripheralFeatureSupport(rawValue: value)! })
    }
    
    /// Returns a signal producer for the peripheral's `bootloaderVersion` property.
    public var bootloaderVersion: SignalProducer<String?, NoError>
    {
        return producerFor(keyPath: "bootloaderVersion")
    }
    
    /// Returns a signal producer for the peripheral's `style` property.
    public var style: SignalProducer<RLYPeripheralStyle, NoError>
    {
        return producerFor(keyPath: "style", defaultValue: RLYPeripheralStyle.undetermined.rawValue)
            .map({ value in RLYPeripheralStyle(rawValue: value)! })
    }

    /// Returns a signal producer for the peripheral's `band` property.
    public var band: SignalProducer<RLYPeripheralBand, NoError>
    {
        return producerFor(keyPath: "band", defaultValue: RLYPeripheralBand.undetermined.rawValue)
            .map({ value in RLYPeripheralBand(rawValue: value)! })
    }

    /// A signal producer for the peripheral's `stone` property.
    public var stone: SignalProducer<RLYPeripheralStone, NoError>
    {
        return producerFor(keyPath: "stone", defaultValue: RLYPeripheralStone.undetermined.rawValue)
            .map({ value in RLYPeripheralStone(rawValue: value)! })
    }
}
