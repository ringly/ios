import ReactiveSwift
import UIKit
import enum Result.NoError

final class DFUOpenSettingsViewController: UIViewController, DFUPropertyChildViewController
{
    // MARK: - State
    enum State { case first, second }
    let state = MutableProperty(State.first)

    // MARK: - Subviews
    fileprivate let contentViews = (
        openSettings: DFUOpenSettingsSubview.openSettingsView(with: UIImage(asset: .settingsHomeScreen)),
        tapBluetooth: DFUOpenSettingsSubview.bluetoothView(),
        findRingly: DFUOpenSettingsSubview.findRinglyView(),
        forgetThisDevice: DFUOpenSettingsSubview.forgetThisDeviceView()
    )

    fileprivate let detailLabel = UILabel.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // create a vertical stack view for even padding and centering
        let stack = UIStackView.newAutoLayout()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.spacing = 10
        view.addSubview(stack)

        stack.autoPinEdgeToSuperview(edge: .top, inset: DFUStartingViewController.topInset)
        stack.autoPinEdgeToSuperview(edge: .bottom, inset: DFUStartingViewController.topInset)
        stack.autoSet(dimension: .width, to: 320, relation: .lessThanOrEqual)
        stack.autoFloatInSuperview(alignedTo: .vertical)

        // displays the title for the current mode
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.preferredMaxLayoutWidth = 300
        titleLabel.textColor = .white
        stack.addArrangedSubview(titleLabel)

        // add content views to the middle of the stack
        stack.addArrangedSubview(contentViews.openSettings)
        stack.addArrangedSubview(contentViews.tapBluetooth)
        stack.addArrangedSubview(contentViews.findRingly)
        stack.addArrangedSubview(contentViews.forgetThisDevice)

        // add a detail text label to display more information about the current mode
        detailLabel.alpha = 0
        detailLabel.numberOfLines = 0
        stack.addArrangedSubview(detailLabel)

        // bind contents of labels to current mode
        state.producer.startWithValues({ [weak self, weak titleLabel] state in
            titleLabel?.attributedText = state.text
            self?.detailLabel.attributedText = state.detailText
        })
    }

    fileprivate var playedAnimation = false

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        guard !playedAnimation else { return }
        playedAnimation = true

        FakeTouchView.show(at: contentViews.openSettings.contentArea.bounds.mid, in: contentViews.openSettings.contentArea)
            .delay(1, on: QueueScheduler.main)
            .then(FakeTouchView.show(
                at: CGPoint(x: 17, y: contentViews.tapBluetooth.contentArea.bounds.midY),
                in: contentViews.tapBluetooth.contentArea)
            )
            .delay(1, on: QueueScheduler.main)
            .then(FakeTouchView.show(at: CGPoint(x: 85, y: 35), in: contentViews.findRingly.contentArea))
            .delay(1, on: QueueScheduler.main)
            .then(FakeTouchView.show(
                at: contentViews.forgetThisDevice.contentArea.bounds.mid,
                in: contentViews.forgetThisDevice.contentArea)
            )
            .delay(1, on: QueueScheduler.main)
            .then(UIView.animationProducer(duration: 0.5, animations: { [weak self] in
                self?.detailLabel.alpha = 1
            }))
            .start()
    }
}

extension DFUOpenSettingsViewController.State
{
    fileprivate var text: NSAttributedString
    {
        return tr(self == .first ? .dfuUnpairFirstText : .dfuUnpairSecondText).rly_DFUTitleString()
    }

    fileprivate var detailText: NSAttributedString
    {
        return tr(self == .first ? .dfuUnpairFirstDetailText : .dfuUnpairSecondDetailText).attributes(
            color: .white,
            font: .gothamBook(12),
            paragraphStyle: .with(alignment: .center, lineSpacing: 6),
            tracking: 133
        )
    }
}

extension FakeTouchView
{
    static func show(at point: CGPoint, in view: UIView) -> SignalProducer<(), NoError>
    {
        return SignalProducer { observer, _ in
            FakeTouchView.show(at: point, of: view, completion: observer.sendCompleted)
        }
    }
}
