import QuartzCore
import ReactiveSwift
import Result

extension CATransaction
{
    /**
     A signal producer that will execute a `CATransaction`.

     - parameter duration:   The duration of the transaction.
     - parameter animations: The animations to perform during the transaction.
     */
    public static func producerWithDuration(_ duration: TimeInterval, animations: @escaping () -> ())
        -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, _ in
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setCompletionBlock({
                observer.sendCompleted()
            })

            animations()

            CATransaction.commit()
        }
    }
}
