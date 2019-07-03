import Foundation
import ReactiveSwift
import enum Result.NoError
import func RinglyExtensions.timerUntil

let sevenDaysInSeconds:TimeInterval = 60.0 * 60.0 * 24.0 * 7.0

extension ModifiableMutablePropertyType where Value == ReviewsState?
{
    func transitionReviewsState(after duration:TimeInterval = sevenDaysInSeconds) {
        guard let value = self.value else {
            self.value = .displayAfter(Date().addingTimeInterval(duration))
            return
        }
        
        if case let .displayAfter(date) = value, date.compare(Date()) == .orderedAscending
        {
            self.value = .display(.prompt)
        }
    }
}

extension MutablePropertyProtocol where Value == ReviewsTextFeedback?
{
    /// When the property has a non-`nil` value, starts a producer derived from the value. If the producer completes,
    /// sets the property's value to `nil`. If the producer fails, does nothing.
    ///
    /// - Parameter makeProducer: A function to create a success/fail producer.
    @discardableResult
    func startUpdating<Error>(makeProducer: @escaping (ReviewsTextFeedback) -> SignalProducer<(), Error>)
        -> Disposable
    {
        return producer.promoteErrors(Error.self).flatMapOptional(.latest, transform: { value in
            makeProducer(value).on(completed: { [weak self] in
                self?.value = nil
            })
        }).start()
    }
}
