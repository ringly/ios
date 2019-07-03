import UIKit
import ReactiveSwift
import enum Result.NoError

extension UIApplication
{
    /// A producer for the current date, updating when a significant change occurs.
    public var significantDateProducer: SignalProducer<Date, NoError>
    {
        return SignalProducer(NotificationCenter.default.reactive
            .notifications(forName: NSNotification.Name.UIApplicationSignificantTimeChange, object: self))
            .initializeAndReplaceFuture({ Date() })
    }

    /// A producer that yields `true` when the application is in the foreground, and `false` otherwise.
    public var activeProducer: SignalProducer<Bool, NoError>
    {
        let center = NotificationCenter.default

        return SignalProducer.concat([
            SignalProducer<Bool, NoError>.deferValue { [weak self] in self?.applicationState == .active },
            SignalProducer(Signal.merge(
                center.reactive.notifications(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: self)
                    .map({ _ in true }),
                center.reactive.notifications(forName: NSNotification.Name.UIApplicationWillResignActive, object: self)
                    .map({ _ in false })
            ))
        ])
    }
}
