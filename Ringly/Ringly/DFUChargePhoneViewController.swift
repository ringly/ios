import ReactiveSwift
import RinglyDFU
import UIKit
import enum Result.NoError

final class DFUChargePhoneViewController: UIViewController, DFUPropertyChildViewController
{
    // MARK: - State
    typealias State = PhoneInChargerState
    let state = MutableProperty(PhoneInChargerState.waiting)

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // add title and detail labels at the top of the view
        let titleLabel = DFUUnderlineLabel.newAutoLayout()
        view.addSubview(titleLabel)

        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: DFUStartingViewController.topInset)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        let detailLabel = UILabel.newAutoLayout()
        detailLabel.attributedText = tr(.dfuPhoneBatteryDetailText).rly_DFUBodyString()
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)

        detailLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        detailLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 25)
        detailLabel.autoSet(dimension: .width, to: 282)
        detailLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        // add content view below the title and detail labels
        let contentView = DFUChargePhoneContentView.newAutoLayout()
        view.addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(excluding: .top)
        contentView.autoPin(edge: .top, to: .bottom, of: detailLabel, offset: 42)

        // bind the title label content to the view's state
        let completeProducer = state.producer.map({ $0 == .inCharger })

        completeProducer.startCrossDissolve(in: titleLabel, duration: 0.25, action: { complete in
            titleLabel.text = tr(complete ? .dfuPhoneBatteryCompleteText : .dfuPhoneBatteryText)
        })

        // bind animation phase to content view
        animationPhase.producer.start(animationDuration: 0.25, action: { phase in
            detailLabel.alpha = phase == .done ? 0 : 1
            contentView.animationPhase.value = phase
            contentView.layoutIfInWindowAndNeeded()
        })
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        animationPhase <~ playingAnimationPhase.producer.combineLatest(with: state.producer).map({ phase, state in
            state == .inCharger ? .done : phase
        }).skipRepeats()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        playAnimation(override: false)
    }

    // MARK: - Animation
    fileprivate enum AnimationPhase
    {
        case notCharging
        case charging
        case done
    }

    fileprivate let animationPhase = MutableProperty(AnimationPhase.notCharging)
    fileprivate let playingAnimationPhase = MutableProperty(AnimationPhase.notCharging)

    fileprivate var playingAnimation = false
    fileprivate func playAnimation(override: Bool)
    {
        guard !playingAnimation || override else { return }
        playingAnimation = true

        playingAnimationPhase <~ SignalProducer.concat(
            [AnimationPhase.charging, .notCharging].map({ phase in
                SignalProducer(value: phase).delay(2, on: QueueScheduler.main)
            })
        ).on(completed: { [weak self] in self?.playAnimation(override: true) })
    }
}

extension DFUChargePhoneViewController.AnimationPhase
{
    var plugged: Bool
    {
        switch self
        {
        case .notCharging:
            return false
        case .charging, .done:
            return true
        }
    }
}

private final class DFUChargePhoneContentView: UIView
{
    // MARK: - Animation Phase
    let animationPhase = MutableProperty(DFUChargePhoneViewController.AnimationPhase.notCharging)

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add phone and content
        let phone = DFUFakePhoneView.newAutoLayout()
        addSubview(phone)

        phone.autoPinEdgeToSuperview(edge: .top)
        phone.autoAlignAxis(toSuperviewAxis: .vertical)

        let screenContent = DFUChargePhoneScreenContentView.newAutoLayout()
        phone.screen.addSubview(screenContent)
        screenContent.autoPinEdgesToSuperviewEdges()

        // add lightning plug below phone
        let lightningContainer = UIView.newAutoLayout()
        lightningContainer.clipsToBounds = true
        addSubview(lightningContainer)

        lightningContainer.autoPin(edge: .top, to: .bottom, of: phone)
        lightningContainer.autoPinEdgesToSuperviewEdges(excluding: .top)
        lightningContainer.autoSet(dimension: .height, to: 87)

        let lightning = DFULightningView.newAutoLayout()
        lightningContainer.addSubview(lightning)
        lightning.autoPinEdgesToSuperviewEdges(excluding: .top)
        let lightningTop = lightning.autoPinEdgeToSuperview(edge: .top)

        animationPhase.producer.startWithValues({ state in
            lightningTop.constant = state.plugged ? -kDFULightingViewPlugHeight : 18
        })

        screenContent.animationPhase <~ animationPhase
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
}

private final class DFUChargePhoneScreenContentView: UIView
{
    // MARK: - State
    let animationPhase = MutableProperty(DFUChargePhoneViewController.AnimationPhase.notCharging)

    // MARK: - Initialization
    fileprivate func setup()
    {
        let batteryContainer = UIView.newAutoLayout()
        addSubview(batteryContainer)
        batteryContainer.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0))

        let battery = UIImageView.newAutoLayout()
        battery.image = UIImage(asset: .dfuBattery)
        batteryContainer.addSubview(battery)
        battery.autoCenterInSuperview()

        let batteryBolt = UIImageView.newAutoLayout()
        batteryBolt.image = UIImage(asset: .dfuBolt)
        batteryContainer.addSubview(batteryBolt)
        batteryBolt.autoCenterInSuperview()

        let batteryExclamation = UIImageView.newAutoLayout()
        batteryExclamation.image = UIImage(asset: .dfuExclamation)
        batteryContainer.addSubview(batteryExclamation)

        batteryExclamation.autoAlign(axis: .horizontal, toSameAxisOf: batteryContainer)
        batteryExclamation.autoAlign(axis: .vertical, toSameAxisOf: batteryContainer, offset: 1)

        let check = UIImageView.newAutoLayout()
        check.image = UIImage(asset: .dfuBatteryCheck)
        addSubview(check)
        check.autoCenterInSuperview()

        animationPhase.producer.startWithValues({ [weak self] phase in
            batteryContainer.alpha = phase == .notCharging || phase == .charging ? 1 : 0
            batteryBolt.alpha = phase == .charging ? 1 : 0
            batteryExclamation.alpha = phase == .notCharging ? 1 : 0
            check.alpha = phase == .done ? 1 : 0

            self?.backgroundColor = phase == .done || phase == .charging
                ? UIColor(white: 1, alpha: 0.5)
                : UIColor(red: 0, green: 0.227, blue: 0.518, alpha: 0.2)
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
}
