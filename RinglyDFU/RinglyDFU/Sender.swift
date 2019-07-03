import Foundation
import ReactiveSwift

/// A protocol for types that can send peripherals to bootloader mode for performing DFU.
internal protocol Sender
{
    /// A producer for sending the
    func sendProducer() -> SignalProducer<State, NSError>
}
