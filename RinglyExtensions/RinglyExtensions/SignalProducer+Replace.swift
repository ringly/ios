import ReactiveSwift

extension SignalProducerProtocol
{
    // MARK: - Initializing and Replacing Future Values

    /**
     Returns a producer that yields the value of `function` immediately when started, then yields the result of
     `function` whenever the receiver yields a value.

     This is useful for integrating with `NSNotificationCenter`, for example:

         NotificationCenter.default
             .rac_notifications(NSCurrentLocaleDidChangeNotification, object: nil)
             .initializeAndReplaceFuture({ Calendar.current })

     ...will create a producer for the current calendar.

     - parameter function: The function to invoke.
     */
    
    public func initializeAndReplaceFuture<Other>(_ function: @escaping () -> Other) -> SignalProducer<Other, Error>
    {
        return SignalProducer([
            SignalProducer.`defer` { SignalProducer(value: function()) },
            self.void.map(function)
        ]).flatten(.concat)
    }
}
