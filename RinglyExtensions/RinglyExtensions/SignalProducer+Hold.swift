import ReactiveSwift
import enum Result.NoError

extension SignalProducerProtocol
{
    // MARK: - Holding Values

    /// Once `after` sends a value, holds values sent by the receiver until `until` sends a value, then sends only the
    /// latest value sent by the receiver.
    ///
    /// Failure events are sent immediately. Other terminating events currently require termination of all producers.
    ///
    /// - parameter initial: This function will be evaluated when the returned producer is started. If it returns
    ///                      `true`, the receiver will be held initially. The default value of this parameter is a
    ///                      function that returns `false`.
    /// - parameter after:   A producer to hold values after.
    /// - parameter until:   A producer to release held values.
    public func hold(initial: @escaping () -> Bool = { false },
                     after: SignalProducer<(), NoError>,
                     until: SignalProducer<(), NoError>)
        -> SignalProducer<Value, Error>
    {
        let values = SignalProducer.merge(
            after.map({ _ in HoldValue<Value>.after }).promoteErrors(Error.self),
            until.map({ _ in HoldValue<Value>.until }).promoteErrors(Error.self),
            map(HoldValue<Value>.next)
        )

        return SignalProducer { observer, disposable in
            typealias State = (holding: Bool, heldValue: Value?)
            let state = Atomic<State>((holding: initial(), heldValue: Value?.none))

            disposable += values.start { event in
                switch event
                {
                case let .value(holdValue):
                    switch holdValue
                    {
                    case .after:
                        state.modify({ $0 = (holding: true, heldValue: $0.heldValue) })

                    case .until:
                        if let heldValue = state.modify({ state -> Value? in
                                let oldValue = state.heldValue
                                state = (holding: false, heldValue: nil)
                                return oldValue
                            })
                        {
                            observer.send(value: heldValue)
                        }

                    case let .next(value):
                        if state.modify({ state -> Bool in
                                if state.holding
                                {
                                    state = (holding: true, heldValue: value)
                                    return false
                                }
                                else
                                {
                                    state = (holding: false, heldValue: nil)
                                    return true
                                }
                            })
                        {
                            observer.send(value: value)
                        }
                    }
                case let .failed(error):
                    observer.send(error: error)
                case .completed:
                    observer.sendCompleted()
                case .interrupted:
                    observer.sendInterrupted()
                }
            }
        }
    }

    // MARK: - Holding Values Based on Notifications

    /// Holds values based on notifications.
    ///
    /// - Parameters:
    ///   - initial: A function to determine if values should be held initially.
    ///   - afterNotification: The notification to hold values after.
    ///   - untilNotification: The notification to release held values after.
    ///   - center: The notification center to observe notifications on.
    ///   - object: The object to require for notifications, or `nil`.
    func holdNotification(initial: @escaping () -> Bool,
                          after afterNotification: NSNotification.Name,
                          until untilNotification: NSNotification.Name,
                          from center: NotificationCenter,
                          object: AnyObject?)
        -> SignalProducer<Value, Error>
    {
        return hold(
            initial: initial,
            after: SignalProducer(center.reactive.notifications(forName: afterNotification, object: object)).void,
            until: SignalProducer(center.reactive.notifications(forName: untilNotification, object: object)).void
        )
    }

    // MARK: - Holding Values Based on Application State

    /// Holds values based on application notification.
    ///
    /// - parameter initial:           A function to determine if values should be held initially.
    /// - parameter afterNotification: The application notification to hold values after.
    /// - parameter untilNotification: The application notification to release held values after.
    func holdApplicationNotification(initial: @escaping (UIApplication) -> Bool,
                                     after afterNotification: NSNotification.Name,
                                     until untilNotification: NSNotification.Name)
        -> SignalProducer<Value, Error>
    {
        let application = UIApplication.shared

        return holdNotification(
            initial: { initial(application) },
            after: afterNotification,
            until: untilNotification,
            from: NotificationCenter.default,
            object: application
        )
    }

    /// Holds the producer's `next` values until the application is active.
    ///
    /// When the application becomes active, at most one `next` will be sent. Previous `next` values will be discarded.
    ///
    /// Failure events are sent immediately. Other terminating events currently require termination of all producers.
    public func holdUntilActive() -> SignalProducer<Value, Error>
    {
        return holdApplicationNotification(
            initial: { $0.applicationState != .active },
            after: NSNotification.Name.UIApplicationDidEnterBackground,
            until: NSNotification.Name.UIApplicationDidBecomeActive
        )
    }


    /// Holds the producer's `next` values until protected data is available.
    ///
    /// When protected data becomes available, at most one `next` will be sent. Previous `next` values will be
    /// discarded.
    ///
    /// Failure events are sent immediately. Other terminating events currently require termination of all producers.
    public func holdUntilProtectedDataIsAvailable() -> SignalProducer<Value, Error>
    {
        return holdApplicationNotification(
            initial: { !$0.isProtectedDataAvailable },
            after: NSNotification.Name.UIApplicationProtectedDataWillBecomeUnavailable,
            until: NSNotification.Name.UIApplicationProtectedDataDidBecomeAvailable
        )
    }
}

extension SignalProducerProtocol
{
    // MARK: - Deferred Holds

    /// Waits to start the producer until the conditions described by `hold(initial:after:until:) are met.
    ///
    /// - parameter initial: This function will be evaluated when the returned producer is started. If it returns
    ///                      `true`, the receiver will be held initially. The default value of this parameter is a
    ///                      function that returns `false`.
    /// - parameter after:   A producer to hold values after.
    /// - parameter until:   A producer to release held values.
    
    public func deferHold(initial: @escaping () -> Bool = { false },
                          after: SignalProducer<(), NoError>,
                          until: SignalProducer<(), NoError>)
        -> SignalProducer<Value, Error>
    {
        return SignalProducer<(), Error>(value: ())
            .hold(initial: initial, after: after, until: until)
            .take(first: 1)
            .then(producer)
    }

    // MARK: - Deferred Holds Based on Application State

    /// Defer holds values based on application notifications.
    ///
    /// - parameter initial:           A function to determine if values should be held initially.
    /// - parameter afterNotification: The application notification to hold values after.
    /// - parameter untilNotification: The application notification to release held values after.
    
    fileprivate func deferHoldApplicationNotification(initial: @escaping (UIApplication) -> Bool,
                                                      afterNotification: NSNotification.Name,
                                                      untilNotification: NSNotification.Name)
        -> SignalProducer<Value, Error>
    {
        let application = UIApplication.shared
        let center = NotificationCenter.default

        return deferHold(
            initial: { initial(application) },
            after: SignalProducer(center.reactive.notifications(forName: afterNotification, object: application)).void,
            until: SignalProducer(center.reactive.notifications(forName: untilNotification, object: application)).void
        )
    }

    /// Waits to start the producer until protected data is available.
    
    public func deferUntilProtectedDataIsAvailable() -> SignalProducer<Value, Error>
    {
        return deferHoldApplicationNotification(
            initial: { !$0.isProtectedDataAvailable },
            afterNotification: NSNotification.Name.UIApplicationProtectedDataWillBecomeUnavailable,
            untilNotification: NSNotification.Name.UIApplicationProtectedDataDidBecomeAvailable
        )
    }
}

private enum HoldValue<Value>
{
    case after
    case until
    case next(Value)
}
