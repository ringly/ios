import ReactiveSwift
import Result
import RinglyKit

// MARK: Extension
public extension Reactive where Base: RLYPeripheralObservation
{
    // MARK: - Utility

    /**
     Returns a producer that adds a `ReactivePeripheralObserver` to the peripheral's observers, and removes it when
     disposed.
     
     - parameter configuration: A function, in which the reactive observer can be configured to send values or errors.
     */
    fileprivate func observerProducer<Value>(configuration: @escaping (ReactivePeripheralObserver, @escaping (Value) -> ()) -> ())
        -> SignalProducer<Value, NoError>
    {
        return SignalProducer { sink, disposable in
            let observer = ReactivePeripheralObserver()
            configuration(observer, sink.send)
            
            self.base.add(observer: observer)
            
            disposable += ActionDisposable {
                self.base.remove(observer: observer)
            }
        }
    }
    
    // MARK: - ANCS
    
    /// A signal producer that will send a value whenever the peripheral receives an ANCS notification.
    public var ANCSNotification: SignalProducer<RLYANCSNotification, NoError>
    {
        return observerProducer { $0.didReceiveANCSNotification = $1 }
    }
    
    // MARK: - Settings Responses
    
    /// A signal producer that will send a value whenever the peripheral sends an application setting confirmation.
    public var applicationSettingResponse: SignalProducer<RLYPeripheralApplicationSettingResponse, NoError>
    {
        return observerProducer { $0.applicationSettingResponse = $1 }
    }
    
    /// A signal producer that will send a value whenever the peripheral sends a contact setting confirmation.
    public var contactSettingResponse: SignalProducer<RLYPeripheralContactSettingResponse, NoError>
    {
        return observerProducer { $0.contactSettingResponse = $1 }
    }

    // MARK: - Activity Tracking
    public var activityTrackingEvents: SignalProducer<RLYPeripheralActivityTrackingEvent, NoError>
    {
        return observerProducer { $0.activityEvent = $1 }
    }

    // MARK: - Taps

    /// A signal producer that will send the number of taps when the peripheral is tapped by the user.
    public var receivedTaps: SignalProducer<Int, NoError>
    {
        return observerProducer { $0.taps = $1 }
    }

    // MARK: - Application Errors

    /// A signal producer that will send peripheral application errors when they occur.
    public var applicationError: SignalProducer<(code: UInt, line: UInt, file: String), NoError>
    {
        return observerProducer { $0.applicationError = $1 }
    }

    // MARK: - Flash Log

    /// A signal producer that will send all flash log data items, as they are received.
    public var flashLog: SignalProducer<Data, NoError>
    {
        return observerProducer { $0.flashLog = $1 }
    }

    /// A signal producer that will send complete flash log data items, once a completion message has been sent.
    public var accumulatedFlashLog: SignalProducer<Data, NoError>
    {
        return flashLog.producerByAccumulatingUntilEmpty
    }
}

// MARK: - Observer Class
private final class ReactivePeripheralObserver: NSObject, RLYPeripheralObserver
{
    // MARK: - ANCS Notifications
    var didReceiveANCSNotification: (RLYANCSNotification) -> () = { _ in }
    
    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, didReceive ANCSNotification: RLYANCSNotification)
    {
        didReceiveANCSNotification(ANCSNotification)
    }
    
    // MARK: - Application Settings
    var applicationSettingResponse: (RLYPeripheralApplicationSettingResponse) -> () = { _ in }
    
    @objc fileprivate func peripheral(
        _ peripheral: RLYPeripheral,
        confirmedApplicationSettingWithFragment fragment: String,
        color: RLYColor,
        vibration: RLYVibration)
    {
        applicationSettingResponse(.added(fragment: fragment, color: color, vibration: vibration))
    }
    
    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, failedApplicationSettingWithFragment fragment: String)
    {
        applicationSettingResponse(.failed(fragment: fragment))
    }
    
    @objc fileprivate func peripheralConfirmedApplicationSettingDeleted(_ peripheral: RLYPeripheral)
    {
        applicationSettingResponse(.deleted)
    }
    
    @objc fileprivate func peripheralConfirmedApplicationSettingsCleared(_ peripheral: RLYPeripheral)
    {
        applicationSettingResponse(.cleared)
    }
    
    // MARK: - Contact Settings
    var contactSettingResponse: (_ response: RLYPeripheralContactSettingResponse) -> () = { _ in }
    
    @objc fileprivate func peripheral(
        _ peripheral: RLYPeripheral,
        confirmedContactSettingWithFragment fragment: String,
        color: RLYColor)
    {
        contactSettingResponse(.added(fragment: fragment, color: color))
    }
    
    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, failedContactSettingWithFragment fragment: String)
    {
        contactSettingResponse(.failed(fragment: fragment))
    }
    
    @objc fileprivate func peripheralConfirmedContactSettingDeleted(_ peripheral: RLYPeripheral)
    {
        contactSettingResponse(.deleted)
    }
    
    @objc fileprivate func peripheralConfirmedContactSettingsCleared(_ peripheral: RLYPeripheral)
    {
        contactSettingResponse(.cleared)
    }

    // MARK: - Activity
    var activityEvent: (_ event: RLYPeripheralActivityTrackingEvent) -> () = { _ in }

    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, read update: RLYActivityTrackingUpdate)
    {
        activityEvent(.value(update))
    }

    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, encounteredErrorWhileReadingActivityTrackingUpdates error: Error)
    {
        activityEvent(.failed(error as NSError))
    }

    @objc fileprivate func peripheralCompletedReadingActivityData(_ peripheral: RLYPeripheral)
    {
        activityEvent(.completed)
    }

    // MARK: - Taps
    var taps: (Int) -> () = { _ in }

    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, receivedTapsWithCount tapCount: UInt)
    {
        taps(Int(tapCount))
    }

    // MARK: - Application Errors
    var applicationError: (UInt, UInt, String) -> () = { _ in }

    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral,
                                  encounteredApplicationErrorWithCode code: UInt,
                                  lineNumber: UInt,
                                  filename: String)
    {
        applicationError(code, lineNumber, filename)
    }

    // MARK: - Flash Log
    var flashLog: (Data) -> () = { _ in }

    @objc fileprivate func peripheral(_ peripheral: RLYPeripheral, readFlashLogData data: Data)
    {
        flashLog(data)
    }
}

// MARK: - Signal Producer Extensions
extension SignalProducerProtocol where Value == Data
{
    var producerByAccumulatingUntilEmpty: SignalProducer<Data, Error>
    {
        return SignalProducer { observer, disposable in
            var stored: [Data] = []

            disposable += self.start { event in
                switch event
                {
                case let .value(data):
                    if data.count == 0
                    {
                        guard stored.count > 0 else { return }

                        let length = stored.reduce(0, { $0 + $1.count })
                        var mutable = Data(capacity: length)
                        stored.forEach({ mutable.append($0) })
                        stored = []

                        observer.send(value: mutable)
                    }
                    else
                    {
                        stored.append(data)
                    }
                case let .failed(error):
                    observer.send(error: error)
                case .interrupted:
                    observer.sendInterrupted()
                case .completed:
                    observer.sendCompleted()
                }
            }
        }
    }
}

// MARK: - Value Types

/// Enumerates all possible application setting confirmation responses.
public enum RLYPeripheralApplicationSettingResponse: Equatable
{
    /// The application was added.
    case added(fragment: String, color: RLYColor, vibration: RLYVibration)
    
    /// The application failed to be added.
    case failed(fragment: String)
    
    /// A application was deleted.
    case deleted
    
    /// The applications were cleared.
    case cleared
}

public func ==(lhs: RLYPeripheralApplicationSettingResponse, rhs: RLYPeripheralApplicationSettingResponse) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.added(lhsFragment, lhsColor, lhsVibration), .added(rhsFragment, rhsColor, rhsVibration)):
        return lhsFragment == rhsFragment
            && lhsColor.red == rhsColor.red
            && lhsColor.green == rhsColor.green
            && lhsColor.blue == rhsColor.blue
            && lhsVibration == rhsVibration

    case let (.failed(lhsFragment), .failed(rhsFragment)):
        return lhsFragment == rhsFragment

    case (.deleted, .deleted):
        return true

    case (.cleared, .cleared):
        return true

    default:
        return false
    }
}

/// Enumerates all possible contact setting confirmation responses.
public enum RLYPeripheralContactSettingResponse: Equatable
{
    /// The contact was added.
    case added(fragment: String, color: RLYColor)
    
    /// The contact failed to be added.
    case failed(fragment: String)
    
    /// A contact was deleted.
    case deleted
    
    /// The contacts were cleared.
    case cleared
}

public func ==(lhs: RLYPeripheralContactSettingResponse, rhs: RLYPeripheralContactSettingResponse) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.added(lhsFragment, lhsColor), .added(rhsFragment, rhsColor)):
        return lhsFragment == rhsFragment
            && lhsColor.red == rhsColor.red
            && lhsColor.green == rhsColor.green
            && lhsColor.blue == rhsColor.blue

    case let (.failed(lhsFragment), .failed(rhsFragment)):
        return lhsFragment == rhsFragment

    case (.deleted, .deleted):
        return true

    case (.cleared, .cleared):
        return true

    default:
        return false
    }
}

/// Enumerates the types of activity tracking events a peripheral can notify its observers of, as a single type.
public enum RLYPeripheralActivityTrackingEvent
{
    // MARK: - Cases

    /// The peripheral received an activity tracking update.
    case value(RLYActivityTrackingUpdate)

    /// The peripheral encountered an error whilst reading activity tracking updates.
    case failed(NSError)

    /// The peripheral received a notification that there are no more activity tracking updates.
    case completed
}

extension RLYPeripheralActivityTrackingEvent: Equatable {}
public func ==(lhs: RLYPeripheralActivityTrackingEvent, rhs: RLYPeripheralActivityTrackingEvent) -> Bool
{
    switch (lhs, rhs)
    {
    case let (.value(lhsUpdate), .value(rhsUpdate)):
        return lhsUpdate == rhsUpdate
    case let (.failed(lhsError), .failed(rhsError)):
        return lhsError == rhsError
    case (.completed, .completed):
        return true
    default:
        return false
    }
}

extension RLYPeripheralActivityTrackingEvent
{
    // MARK: - Properties

    /// The event's update, if any.
    public var update: RLYActivityTrackingUpdate?
    {
        switch self
        {
        case .value(let update):
            return update

        default:
            return nil
        }
    }

    /// The event's error, if any.
    public var error: NSError?
    {
        switch self
        {
        case let .failed(error):
            return error

        default:
            return nil
        }
    }
}
