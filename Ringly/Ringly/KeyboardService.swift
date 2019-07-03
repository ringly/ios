import ReactiveSwift
import Result
import UIKit

/// A service for tracking the current position of the keyboard, and subscribing to updates.
final class KeyboardService: NSObject
{
    // MARK: - Observation

    /// The keyboard event type.
    typealias Event = (frame: CGRect, duration: TimeInterval, curve: UIViewAnimationCurve)

    /// A signal of events that cause a change in keyboard state.
    let events: Signal<Event, NoError>

    /// The current keyboard frame.
    let frame: Property<CGRect>

    /// A signal producer that passes the current frame synchronously, then passes the frames of future events inside
    /// an animation block.
    var animationProducer: SignalProducer<CGRect, NoError>
    {
        let animations = events.flatMap(.merge, transform: { event -> SignalProducer<CGRect, NoError> in
            SignalProducer { observer, _ in
                UIView.animate(withDuration: event.duration, animations: {
                    UIView.setAnimationCurve(event.curve)
                    observer.send(value: event.frame)
                    observer.sendCompleted()
                })
            }
        })

        return frame.producer.take(first: 1).concat(SignalProducer(animations))
    }

    // MARK: - Initialization

    /// Initializes a keyboard service.
    override init()
    {
        // create a signal pipe for keyboard events
        let (events, observer) = Signal<Event, NoError>.pipe()
        self.events = events

        // create frame property before super.init
        let frame = MutableProperty(CGRect.zero)
        self.frame = Property(frame)

        super.init()

        // bind the frame property and send events to the signal observer
        let notifications = NotificationCenter.default.reactive
            .notifications(forName: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        frame <~ SignalProducer(notifications)
            .take(until: reactive.lifetime.ended)
            .map({ notification -> Event? in
                if let info = notification.userInfo,
                   let frame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                   let duration = info[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
                   let curve = (info[UIKeyboardAnimationCurveUserInfoKey] as? UIViewAnimationCurve.RawValue)
                        .flatMap(UIViewAnimationCurve.init)
                {
                    return (frame, duration, curve)
                }
                else
                {
                    return nil
                }
            })
            .skipNil()
            .on(completed: observer.sendCompleted, value: { observer.send(value: $0) })
            .map({ frame, _, _ in frame })
    }
}
