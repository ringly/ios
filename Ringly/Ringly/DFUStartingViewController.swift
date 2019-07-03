import ReactiveSwift
import RinglyDFU
import RinglyExtensions
import UIKit

final class DFUStartingViewController: UIViewController, DFUPropertyChildViewController
{
    // MARK: - State
    typealias State = DFUStartingState?
    let state = MutableProperty(DFUStartingState?.none)

    // MARK: - DFU Controller
    var DFUController: RinglyDFU.DFUController?

    // MARK: - Subviews
    fileprivate let container = ContainerViewController()
    let cancel = UIButton.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // add cancel button
        view.addSubview(cancel)
        cancel.autoSet(dimension: .height, to: 44)
        cancel.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)

        let closeXImageView = UIImageView.newAutoLayout()
        closeXImageView.image = Asset.alertClose.image.withRenderingMode(.alwaysTemplate)
        closeXImageView.tintColor = UIColor.white
        closeXImageView.contentMode = .scaleAspectFit
        
        cancel.addSubview(closeXImageView)
        closeXImageView.autoSetDimensions(to: CGSize.init(width: 14, height: 14))
        closeXImageView.autoPinEdgeToSuperview(edge: .top, inset: 20)
        closeXImageView.autoPinEdgeToSuperview(edge: .left, inset: 20)

        
        // add container view controller
        addChildViewController(container)
        view.addSubview(container.view)

        container.childTransitioningDelegate = self

        container.view.autoPin(edge: .top, to: .bottom, of: cancel)
        container.view.autoPinEdgesToSuperviewEdges(excluding: .top)
        container.didMove(toParentViewController: self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // update interface
        let container = self.container

        state.producer
            .mapOptional(DFUStartingViewController.updateContainerFunction)
            .startWithValues({ updateContainer in
                DispatchQueue.main.async(execute: {
                    updateContainer?(container)
                })
            })

        // confirm peripheral-in-charger interface
        container.childViewController.producer
            .map({ $0 as? DFUChargePeripheralViewController })
            .flatMapOptional(.latest, transform: { $0.confirmedProducer })
            .skipNil()
            .startWithValues({ [weak self] _ in self?.DFUController?.confirmPeripheralInCharger() })

        // confirm phone-in-charger interface
        state.producer
            .filter({ state in state?.isPhoneInCharger ?? false })
            .take(first: 1)
            .then(timer(interval: .seconds(4), on: QueueScheduler.main).take(first: 1))
            .startWithCompleted({ [weak self] in self?.DFUController?.confirmPhoneInCharger() })
    }

    // MARK: - Layout
    static var topInset: CGFloat
    {
        return DeviceScreenHeight.current.select(four: 5, preferred: 40)
    }
}

extension DFUStartingViewController
{
    // MARK: - Container View Controller

    /**
     Returns a container view controller update function for the specified DFU state.

     - parameter state: The DFU state.
     */
    fileprivate static func updateContainerFunction(state: DFUStartingState) -> (ContainerViewController) -> ()
    {
        switch state
        {
        case .waitingForForgetThisDevice:
            return DFUOpenSettingsViewController.updateContainer(state: .first)

        case .peripheralInCharger(let chargerState):
            return DFUChargePeripheralViewController.updateContainer(state: chargerState)

        case .phoneInCharger(let chargerState):
            return DFUChargePhoneViewController.updateContainer(state: chargerState)
        }
    }
}

enum DFUStartingState
{
    /// The user is instructed to place his or her peripheral in the charger.
    case peripheralInCharger(RLYPeripheralBatteryState?)

    /// The user is instructed to place his or her phone in the charger.
    case phoneInCharger(PhoneInChargerState)

    /// The controller is waiting for the user to perform "forget this device".
    case waitingForForgetThisDevice
}

extension DFUStartingState
{
    fileprivate var isPhoneInCharger: Bool
    {
        switch self
        {
        case .phoneInCharger(let chargerState):
            return chargerState == .inCharger
        default:
            return false
        }
    }
}

extension DFUStartingViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        return fromViewController != nil ? SlideTransitionController(operation: .push) : nil
    }
}
