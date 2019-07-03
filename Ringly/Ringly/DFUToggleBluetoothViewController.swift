import ReactiveSwift
import RinglyExtensions
import UIKit

final class DFUToggleBluetoothViewController: UIViewController, DFUStatelessChildViewController
{
    // MARK: - Subviews
    fileprivate let phone = DFUToggleBluetoothFakePhoneView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        let height = DeviceScreenHeight.current

        // add labels to the top of the view
        let titleLabel = DFUUnderlineLabel.newAutoLayout()
        titleLabel.text = tr(.dfuToggleBluetoothText)
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(
            edge: .top,
            inset: height.select(four: 10, preferred: DFUStartingViewController.topInset)
        )
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        let bodyLabel = UILabel.newAutoLayout()
        bodyLabel.attributedText = tr(.dfuToggleBluetoothDetailText).rly_DFUBodyString()
        bodyLabel.numberOfLines = 0
        view.addSubview(bodyLabel)

        bodyLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: height.select(four: 19, preferred: 28))
        bodyLabel.autoSet(dimension: .width, to: 282)
        bodyLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        bodyLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        // add phone to the bottom of the view
        let container = UIView.newAutoLayout()
        view.addSubview(container)

        container.autoSet(dimension: .width, to: 282)
        container.autoPin(edge: .top, to: .bottom, of: bodyLabel, offset: height.select(four: 20, preferred: 46))
        container.autoPinEdgeToSuperview(edge: .bottom, inset: height.select(four: 20, preferred: 42))
        container.autoAlignAxis(toSuperviewAxis: .vertical)

        container.addSubview(phone)
        phone.autoFloatInSuperview()
    }

    fileprivate var animating = false

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        guard !animating else { return }
        animating = true
        playAnimation()
    }

    fileprivate func playAnimation()
    {
        timer(interval: .milliseconds(500), on: QueueScheduler.main).take(first: 1)
            .then(UIView.animationProducer(duration: 0.5, animations: { [weak phone] in
                phone?.isControlCenterUp = true
                phone?.layoutIfInWindowAndNeeded()
            }))
            .delay(0.5, on: QueueScheduler.main)
            .then(UIView.animationProducer(duration: 0.4, animations: { [weak phone] in
                phone?.isBluetoothEnabled = false
            }))
            .delay(0.5, on: QueueScheduler.main)
            .then(UIView.animationProducer(duration: 0.4, animations: { [weak phone] in
                phone?.isBluetoothEnabled = true
            }))
            .delay(0.5, on: QueueScheduler.main)
            .then(UIView.animationProducer(duration: 0.5, animations: { [weak phone] in
                phone?.isControlCenterUp = false
                phone?.layoutIfInWindowAndNeeded()
            }))
            .startWithCompleted({ [weak self] in self?.playAnimation() })
    }
}
