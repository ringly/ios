import Foundation
import ReactiveSwift
import RinglyKit
import enum Result.NoError

extension Reactive where Base: RLYPeripheral
{
    /// A producer that clears the ANCS v2 configuration settings on the receiver whenever the receiver becomes ready.
    ///
    /// This producer is entirely side-effecting and does not send meaningful events.
    
    func clearANCSV2Settings() -> SignalProducer<(), NoError>
    {
        return ready
            .skipNil()
            .on(value: { peripheral in
                peripheral.write(command: RLYClearApplicationSettingsCommand())
                peripheral.write(command: RLYClearContactSettingsCommand())

                do
                {
                    try peripheral.writeConfigurationHash(0)
                }
                catch let error as NSError
                {
                    SLogANCS("Error writing clear configuration hash to \(peripheral.loggingName): \(error)")
                }
            })
            .ignoreValues()
    }
}
