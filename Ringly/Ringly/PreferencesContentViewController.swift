import ReactiveSwift
import RinglyExtensions
import RinglyKit
import PureLayout
import UIKit
import enum Result.NoError

/// Displays preferences settings, and an interface for registering the user with the Ringly API.
final class PreferencesContentViewController : ServicesViewController
{
    // MARK: - Subviews
    fileprivate let versionsLabel = UILabel.newAutoLayout()
    fileprivate let scrollView = UIScrollView.newAutoLayout()
    
    // MARK: - View Loading
    override func loadView()
    {
        // set up the base view
        let view = UIView()
        self.view = view

        // set up the scroll view
        scrollView.indicatorStyle = .white
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()

        // add stack view for preferences
        let stack = UIStackView.newAutoLayout()
        stack.axis = .vertical
        stack.alignment = .fill
        scrollView.addSubview(stack)

        stack.autoPinEdgeToSuperview(edge: .top)
        stack.autoPin(edge: .leading, to: .leading, of: view, offset: 20)
        stack.autoPin(edge: .trailing, to: .trailing, of: view, offset: -20)

        // create sub-controllers
        let profile = ProfileViewController(services: services)
        let switches = PreferencesSwitchesViewController(services: services)

        // title label setup
        let titleBar = UIView.newAutoLayout()
        titleBar.autoSet(dimension: .height, to: NavigationBar.standardHeight)

        let titleLabel = UILabel.newAutoLayout()
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleBar.addSubview(titleLabel)
        titleLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        titleLabel.autoPinEdgeToSuperview(edge: .leading)
        titleLabel.autoPinEdgeToSuperview(edge: .trailing)

        profile.mode.producer.startCrossDissolve(
            in: titleLabel,
            duration: 0.25,
            action: { [weak titleLabel] mode in
                let text = mode == .display ? "SETTINGS" : "EDIT PROFILE"
                titleLabel?.attributedText = UIFont.gothamBook(18).track(250, text).attributedString
            }
        )

        // versions label setup
        versionsLabel.numberOfLines = 0
        versionsLabel.textColor = UIColor(white: 1, alpha: 0.5)
        versionsLabel.textAlignment = .center
        versionsLabel.font = UIFont.gothamBook(10)

        let versionsLabelPadder = UIView.newAutoLayout()
        versionsLabelPadder.autoSet(dimension: .height, to: 10)
        
        // vertically, always start with the profile and switches view controllers
        let viewControllers: [UIViewController] = [
            profile,
            switches,
            PreferencesActivityViewController(services: services),
            PreferencesHelpViewController(services: services)
        ]

        // add the view controllers and separators to the stack view
        typealias PreferencesEither = Either<UIViewController, UIView>

        func addEither(_ either: PreferencesEither)
        {
            switch either
            {
            case .left(let viewController):
                addChildViewController(viewController)
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(viewController.view)
                viewController.didMove(toParentViewController: self)

            case .right(let view):
                stack.addArrangedSubview(view)
            }
        }

        addEither(PreferencesEither.right(titleBar))

        let viewControllerEithers = viewControllers.map(PreferencesEither.left)
        viewControllerEithers.dropLast().forEach({ either in
            addEither(either)
            addEither(PreferencesEither.right(UIView.rly_separatorView(withHeight: 1, color: UIColor.white)))
        })

        viewControllerEithers.suffix(1).forEach(addEither)

        addEither(PreferencesEither.right(versionsLabel))
        addEither(PreferencesEither.right(versionsLabelPadder))
        
        // pin view to the bottom
        let normalBottom = stack.autoPinEdgeToSuperview(edge: .bottom)
        let registerBottom = profile.view.autoPin(edge: .bottom, to: .bottom, of: scrollView)

        profile.mode.producer.startWithValues({ (mode: ProfileViewController.Mode) in
            NSLayoutConstraint.conditionallyActivateConstraints([
                (normalBottom, mode == .display),
                (registerBottom, mode == .edit)
            ])
        })

        // add register overlay over bottom content of the preferences view
        let nonProfileViews = stack.arrangedSubviews.dropFirst(2)

        profile.mode.producer.start(animationDuration: 0.25, action: { mode in
            let expanded = mode == .edit

            nonProfileViews.forEach({
                $0.isUserInteractionEnabled = !expanded
                $0.alpha = expanded ? 0 : 1
            })
        })
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // observe version information for each peripheral
        let peripheralStringsProducer = services.peripherals.peripherals.producer
            .flatMap(.latest, transform: { peripherals in
                SignalProducer.combineLatest(peripherals.map({ $0.reactive.preferencesVersionsString }))
            })

        // insert information about the app build
        let bundle = Bundle.main
        let appVersion = bundle.shortVersion ?? ""
        let buildVersion = bundle.version ?? ""

        let versionsStringProducer = peripheralStringsProducer.map({ strings -> String in
            (["\(appVersion) (\(buildVersion))"] + strings).joined(separator: "\n")
        })

        // bind firmware versions to label
        versionsStringProducer
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] versions in
                self?.versionsLabel.text = versions
            })

        // inset when the keyboard is visible (profile editing)
        services.keyboard.animationProducer.startWithValues({ [weak scrollView] rect in
            let offset = rect.size.height > 0 ? TabBarViewController.tabBarHeight : 0

            scrollView?.contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: rect.size.height - offset,
                right: 0
            )
        })
    }
}

extension PreferencesContentViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        scrollView.setContentOffset(.zero, animated: true)
    }
}

extension Reactive where Base: RLYPeripheral
{
    /// Yields strings describing the firmware and hardware versions of the peripheral.
    fileprivate var preferencesVersionsString: SignalProducer<String, NoError>
    {
        let versions = SignalProducer.combineLatest(
            loggingName,
            applicationVersion,
            bootloaderVersion,
            softdeviceVersion,
            hardwareVersion,
            chipVersion,
            MACAddress
        )

        return versions.map({ name, application, bootloader, softdevice, hardware, chip, MAC -> String in
            // start with the versions all on one line, separated by category with dashes
            var string = [
                name,
                [application, bootloader, softdevice].orQuestions,
                [hardware, chip].orQuestions
            ].joined(separator: " - ")

            if let MACString = MAC
            {
                string += "\n\(MACString)"
            }

            return string
        })
    }
}

extension Sequence where Iterator.Element == String?
{
    /// Returns a string of each element, using the wrapped string if non-`nil`, otherwise `"?"`.
    ///
    /// This is used as an optimization, as it's much quicker to compile than embedding `?? "?"`. The performance can be
    /// revisited as new versions of the Swift compiler are released.
    var orQuestions: String
    {
        return map({ $0 ?? "?" }).joined(separator: " ")
    }
}
