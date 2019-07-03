import ReactiveSwift
import enum Result.NoError

extension SignalProducer
{
    // MARK: - Flattening Producers

    /**
     Creates a signal producer by concatenating an array of producers.
     
     This is a workaround for the ambiguitity issues created by ReactiveCocoa 4.2.0.

     - parameter producers: The producers to concatenate.
     */
    public static func concat<Seq : Sequence, S : SignalProducerProtocol>
        (_ producers: Seq) -> SignalProducer where S.Value == Value, S.Error == Error, Seq.Iterator.Element == S
    {
        return SignalProducer<S, Error>(producers).flatten(.concat)
    }

    /**
     Creates a signal producer by concatenating an array of producers.

     This is a workaround for the ambiguitity issues created by ReactiveCocoa 4.2.0.

     - parameter producers: The producers to concatenate.
     */
    public static func concat(_ producers: SignalProducer<Value, Error>...) -> SignalProducer<Value, Error>
    {
        return concat(producers)
    }
}
