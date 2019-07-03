import ReactiveRinglyKit
import ReactiveSwift
import Result
import RinglyExtensions
import RinglyKit

extension Reactive where Base: RLYPeripheral
{
    /// A signal producer that will send the receiver whenever it is ready to write information to or read information
    /// from. The receiver will be sent multiple times, each time that this becomes the case. When the receiver becomes
    /// unready, sends `nil`.
    ///
    /// The primary conditions are that the peripheral is paired, connected, and validated.
    var ready: SignalProducer<RLYPeripheral?, NoError>
    {
        return readiness.map({ $0 == .ready })
            .skipRepeats()
            .map({ [weak base] ready in ready ? base : nil })
    }

    /// Updates when the peripheral's readiness (or unreadiness) changes.
    var readiness: SignalProducer<RLYPeripheralReadiness, NoError>
    {
        let reasons: SignalProducer<[RLYPeripheralUnreadyReason?], NoError> = SignalProducer.combineLatest([
            paired.map({ $0 ? RLYPeripheralUnreadyReason?.none : RLYPeripheralUnreadyReason.notPaired }),
            connected.map({ $0 ? RLYPeripheralUnreadyReason?.none : RLYPeripheralUnreadyReason.notConnected }),
            validationState.map({ $0 == .validated ? RLYPeripheralUnreadyReason?.none : RLYPeripheralUnreadyReason.notValidated($0) })
        ])

        let firstReason: SignalProducer<RLYPeripheralUnreadyReason?, NoError> = reasons.map({ reasons in reasons.flatMap({ $0 }).first })

        return firstReason.map({ reason in
            reason.map(RLYPeripheralReadiness.unready) ?? .ready
        }).skipRepeats()
    }
}

/// Describes whether or not a peripheral is connected and ready to perform actions.
enum RLYPeripheralReadiness: Equatable
{
    /// The peripheral is ready.
    case ready

    /// The peripheral is not ready. A reason is provided.
    case unready(RLYPeripheralUnreadyReason)
}

func ==(lhs: RLYPeripheralReadiness, rhs: RLYPeripheralReadiness) -> Bool
{
    switch (lhs, rhs)
    {
    case (.ready, .ready):
        return true
    case let (.unready(lhsReason), .unready(rhsReason)):
        return lhsReason == rhsReason
    default:
        return false
    }
}

/// The reason that a `RLYPeripheralReadiness` value is `.unready`.
enum RLYPeripheralUnreadyReason: Equatable
{
    /// The peripheral is not paired.
    case notPaired

    /// The peripheral is not connected.
    case notConnected

    /// The peripheral is not validated. Its current validation state is included.
    case notValidated(RLYPeripheralValidationState)
}

func ==(lhs: RLYPeripheralUnreadyReason, rhs: RLYPeripheralUnreadyReason) -> Bool
{
    switch (lhs, rhs)
    {
    case (.notPaired, .notPaired):
        return true
    case (.notConnected, .notConnected):
        return true
    case let (.notValidated(lhsState), .notValidated(rhsState)):
        return lhsState == rhsState
    default:
        return false
    }
}
