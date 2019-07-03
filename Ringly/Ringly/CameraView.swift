import ReactiveCocoa
import ReactiveSwift
import UIKit
import enum Result.NoError

class CameraView : UIView
{
    // MARK: - Camera Views
    fileprivate let title = CameraTitleView.newAutoLayout()
    fileprivate let buttons = CameraButtonsView.newAutoLayout()

    // MARK: - Onboarding Views
    fileprivate let onboardingTitle = CameraOnboardingTitleView.newAutoLayout()
    fileprivate let onboardingButtons = CameraOnboardingButtonsView.newAutoLayout()
    fileprivate var tapAnimation: TapAnimationView?

    // MARK: - Mode
    let showOnboarding = MutableProperty(false)

    // MARK: -
    let flashView : FlashView = FlashView()

    // double tap gesture recognizer
    fileprivate let tap = UITapGestureRecognizer()

    // pinch to zoom gesture recognizer
    let pinch = UIPinchGestureRecognizer()
    
    let captureSessionView = CaptureSessionView.newAutoLayout()

    // initializers
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

    private func setup()
    {
        // setup top container
        let top = UIView.newAutoLayout()
        addSubview(top)
        top.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        top.autoSet(dimension: .height, to: 100)

        // setup title contents
        top.addSubview(title)
        title.autoPinEdgesToSuperviewEdges()

        top.addSubview(onboardingTitle)
        onboardingTitle.autoPinEdgesToSuperviewEdges()

        // add camera preview view
        captureSessionView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.addSubview(captureSessionView)

        captureSessionView.autoMatch(dimension: .height, to: .width, of: captureSessionView)
        captureSessionView.autoPinEdgeToSuperview(edge: .leading)
        captureSessionView.autoPinEdgeToSuperview(edge: .trailing)
        captureSessionView.autoPin(edge: .top, to: .bottom, of: top)

        let bottom = UIView.newAutoLayout()
        addSubview(bottom)
        bottom.autoPinEdgesToSuperviewEdges(excluding: .top)
        bottom.autoPin(edge: .top, to: .bottom, of: captureSessionView)

        // setup buttons in bottom container
        bottom.addSubview(buttons)
        buttons.autoFloatInSuperview(alignedTo: .horizontal)
        buttons.autoPinEdgeToSuperview(edge: .leading)
        buttons.autoPinEdgeToSuperview(edge: .trailing)

        bottom.addSubview(onboardingButtons)
        onboardingButtons.autoPinEdgesToSuperviewEdges()

        // double tap flip camera gesture recognizer
        tap.numberOfTapsRequired = 2
        self.addGestureRecognizer(tap)

        // pinch to zoom gesture recognizer
        self.addGestureRecognizer(pinch)

        // show different accessory/button views in onboarding/camera modes
        showOnboarding.producer.skipRepeats().startWithValues({ [weak self] in self?.updateOnboardingShown($0) })
    }

    private func updateOnboardingShown(_ showOnboarding: Bool)
    {
        buttons.isHidden = showOnboarding
        title.isHidden = showOnboarding
        onboardingButtons.isHidden = !showOnboarding
        onboardingTitle.isHidden = !showOnboarding

        if showOnboarding && tapAnimation == nil
        {
            let tapAnimation = TapAnimationView.newAutoLayout()
            self.tapAnimation = tapAnimation
            addSubview(tapAnimation)

            tapAnimation.autoPin(edge: .leading, to: .leading, of: captureSessionView)
            tapAnimation.autoPin(edge: .trailing, to: .trailing, of: captureSessionView)
            tapAnimation.autoPin(edge: .top, to: .top, of: captureSessionView)
            tapAnimation.autoPin(edge: .bottom, to: .bottom, of: captureSessionView)
            tapAnimation.addCenterCircle()
        }
        else if !showOnboarding && tapAnimation != nil
        {
            tapAnimation?.removeFromSuperview()
            tapAnimation = nil
        }
    }

    func showOnboardingCompletion() -> SignalProducer<(), NoError>
    {
        return SignalProducer { [weak self] observer, _ in
            UIView.animate(withDuration: 2.5, delay: 0.0, options: [.transitionCrossDissolve], animations: {
                self?.tapAnimation?.tapsComplete()
            }, completion: { _ in
                observer.sendCompleted()
            })
        }
    }

    func flash()
    {
        let flash = FlashView.newAutoLayout()
        flash.completion = { [weak flash] in flash?.removeFromSuperview() }
        addSubview(flash)
        flash.autoPinEdgesToSuperviewEdges()
        flash.flash()
    }
}

extension Reactive where Base: CameraView
{
    // MARK: - Targets
    var captureSession: MutableProperty<CaptureSession?>
    {
        return base.captureSessionView.captureSession
    }

    var useFlash: BindingTarget<Bool>
    {
        return makeBindingTarget(on: UIScheduler(), { base, useFlash in
            base.buttons.flash.setImage(UIImage(asset: useFlash ? .flashOn : .flashOff), for: .normal)
        })
    }

    // MARK: - Signals
    var takePicture: Signal<(), NoError>
    {
        return base.buttons.takePicture.reactive.controlEvents(.touchUpInside).void
    }

    var switchFlash: Signal<(), NoError>
    {
        return base.buttons.flash.reactive.controlEvents(.touchUpInside).void
    }

    var showOnboarding: Signal<(), NoError>
    {
        return base.buttons.info.reactive.controlEvents(.touchUpInside).void
    }

    var switchCamera: Signal<(), NoError>
    {
        return Signal.merge(
            base.buttons.switchCamera.reactive.controlEvents(.touchUpInside).void,
            base.tap.reactive.stateChanged.filter({ $0.state == .ended }).void
        )
    }

    var exit: Signal<(), NoError>
    {
        return base.title.exitButton.reactive.controlEvents(.touchUpInside).void
    }

    var skipOnboarding: Signal<(), NoError>
    {
        return base.onboardingButtons.skipButton.reactive.controlEvents(.touchUpInside).void
    }
}
