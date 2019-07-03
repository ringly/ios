import Foundation
import ReactiveSwift
import enum Result.NoError

extension Calendar
{
    // MARK: - Current Calendar

    /// A signal producer for the current calendar.
    public static var currentCalendarProducer: SignalProducer<Calendar, NoError>
    {
        return SignalProducer(NotificationCenter.default.reactive
            .notifications(forName: NSLocale.currentLocaleDidChangeNotification, object: nil))
            .initializeAndReplaceFuture({ Calendar.current })
    }
}

extension Calendar
{
    // MARK: - Component Timers
    fileprivate func timer(matching components: DateComponents, on scheduler: DateSchedulerProtocol)
        -> SignalProducer<Date, NoError>
    {
        return SignalProducer { observer, disposable in
            let serial = SerialDisposable()
            disposable += serial

            func startNextProducerAfter(_ date: Date)
            {
                serial.inner = self.nextDate(after: date, matching: components, matchingPolicy: .strict).map { end in
                    timerUntil(date: end, on: scheduler).startWithValues(completed)
                }
            }

            func completed(_ date: Date)
            {
                observer.send(value: date)
                startNextProducerAfter(date)
            }

            startNextProducerAfter(scheduler.currentDate)
        }
    }
}

extension Calendar
{
    // MARK: - Daily Timers

    /// A timer that emits the current date whenever the day changes.
    public func dailyTimer(on scheduler: DateSchedulerProtocol) -> SignalProducer<Date, NoError>
    {
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        components.second = 0

        return timer(matching: components, on: scheduler)
    }

    /// A timer that immediately emits the current date, then follows the behavior of `dailyTimer(on:)`.
    public func immediateDailyTimer(on scheduler: DateSchedulerProtocol) -> SignalProducer<Date, NoError>
    {
        return SignalProducer.concat([
            SignalProducer.deferValue({ scheduler.currentDate }),
            dailyTimer(on: scheduler)
        ])
    }
}
