import ReactiveSwift
import UIKit
import enum Result.NoError

final class PreferencesActivityHealthKitView: UIView
{
    // MARK: - State
    let connected = MutableProperty(false)

    // MARK: - Subviews
    fileprivate let connectView = PreferencesActivityConnectHealthKitView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add connected label
        let connectedLabel = UILabel.newAutoLayout()
        connectedLabel.attributedText = "You are connected to the Health app.".preferencesBodyAttributedString
        connectedLabel.textColor = .white
        connectedLabel.numberOfLines = 0
        addSubview(connectedLabel)

        connectedLabel.autoPinEdgeToSuperview(edge: .top)
        connectedLabel.autoFloatInSuperview(alignedTo: .vertical)
        connectedLabel.autoSet(dimension: .width, to: 168, relation: .lessThanOrEqual)
        let connectedToBottom = connectedLabel.autoPinEdgeToSuperview(edge: .bottom)

        // add connect view
        addSubview(connectView)
        connectView.autoPinEdgeToSuperview(edge: .top)
        connectView.autoFloatInSuperview(alignedTo: .vertical)
        let connectToBottom = connectView.autoPinEdgeToSuperview(edge: .bottom)

        // update layout based on state
        connected.producer.startWithValues({ [weak connectView, weak connectedLabel] connected in
            NSLayoutConstraint.conditionallyActivateConstraints([
                (connectToBottom, !connected),
                (connectedToBottom, connected)
            ])

            connectView?.isHidden = connected
            connectedLabel?.isHidden = !connected
        })
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Actions

    /// A producer that sends an event when the user taps the "connect" (to HealthKit) button.
    var connectTappedProducer: SignalProducer<(), NoError>
    {
        return SignalProducer(connectView.control.reactive.controlEvents(.touchUpInside)).void
    }
}
