import ReactiveSwift
import Result
import UIKit

final class DFUURLViewController: ServicesViewController
{
    // MARK: - Subviews
    fileprivate let cancel = ButtonControl.newAutoLayout()

    /// A signal producer that will send a `next` when the user taps the "cancel" button.
    var cancelProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(cancel.reactive.controlEvents(.touchUpInside)).map({ _ in () })
    }

    // MARK: - View Loading
    override func loadView()
    {
        // use a blur view as the root view
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        self.view = view

        // add a vibrancy view as a central container
        let vibrancy = UIVibrancyEffect(blurEffect: blur)
        let container = UIVisualEffectView(effect: vibrancy)
        view.contentView.addSubview(container)

        // add an activity indicator and button
        let activity = DiamondActivityIndicator.newAutoLayout()
        activity.constrainToDefaultSize()
        container.contentView.addSubview(activity)

        cancel.title = "CANCEL"
        container.contentView.addSubview(cancel)

        // layout
        container.autoCenterInSuperview()

        activity.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        activity.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        activity.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        activity.autoAlignAxis(toSuperviewAxis: .vertical)

        cancel.autoSetDimensions(to: CGSize(width: 120, height: 50))
        cancel.autoPin(edge: .top, to: .bottom, of: activity, offset: 20)
        cancel.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        cancel.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        cancel.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
        cancel.autoAlignAxis(toSuperviewAxis: .vertical)
    }

    // MARK: - Status Bar
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}
