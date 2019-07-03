import PureLayout
import ReactiveSwift
import Result
import UIKit

private let handleSize = CGSize(width: 66, height: 66)

final class ConnectViewController: ServicesViewController
{
    // MARK: - Subviews
    
    /// The handle button view.
    fileprivate let handleView = UIButton.newAutoLayout()

    /// The container view controller used to hold the child view controller.
    fileprivate let container = ContainerViewController()

    // MARK: - Manual Overrides

    /// A property describing whether or not the "not connecting" view should be displayed.
    fileprivate let showNotConnecting = MutableProperty(false)

    /// A property describing whether or not the "follow these steps..." view should be displayed.
    fileprivate let showRemovePeripheral = MutableProperty(false)

    /// A property describing whether or not the prompt to enable HealthKit should be displaed.
    fileprivate let showConnectHealthKit = MutableProperty(false)

    // MARK: - Child View Controllers

    /// The navigation controller used for peripherals/peripheral views.
    fileprivate lazy var peripheralsViewController: PeripheralsViewController = { [unowned self] in
        return PeripheralsViewController(services: self.services)
    }()
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = GradientView.purpleBlueGradientView
        self.view = view

        // add container view controller
        container.childTransitioningDelegate = self
        container.addAsEdgePinnedChild(of: self, in: view)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // non-referencing-self reference for use in closures
        let services = self.services
        
        // determine the current overlay view controller type, if any
        let managerState = services.peripherals.managerState.producer
            .observe(on: QueueScheduler.main)

        let overlayTypeProducer = SignalProducer.combineLatest(
            managerState,
            showNotConnecting.producer,
            showRemovePeripheral.producer,
            showConnectHealthKit.producer)
            .map({ managerState, showNotConnecting, showRemovePeripheral, showConnectHealthKit -> UIViewController.Type? in
                switch managerState
                {
                case .poweredOff:
                    return PoweredOffViewController.self

                case .poweredOn:
                    guard !showConnectHealthKit else { return OpenHealthViewController.self }
                    guard !showRemovePeripheral else { return RemovePeripheralViewController.self }
                    guard !showNotConnecting else { return NotConnectingViewController.self }
                    return nil

                case .resetting:
                    return ResettingViewController.self

                case .unauthorized:
                    return UnauthorizedViewController.self

                case .unknown:
                    return nil

                case .unsupported:
                    return UnsupportedViewController.self
                }
            })

        container.childViewController <~ overlayTypeProducer
            .skipRepeats(==)
            .mapOptional({ type -> UIViewController in
                // correctly initialize ServicesViewController subclasses with services
                if let servicesType = type as? ServicesViewController.Type
                {
                    return servicesType.init(services: services)
                }
                else
                {
                    return type.init()
                }
            })
            .map({ [weak self] overlay in overlay ?? self?.peripheralsViewController })

        // show and hide the "not connecting" overlay view
        showNotConnecting <~ activateOverlayProducer(
            type: NotConnectingViewController.self,
            activateProducer: peripheralsViewController.notConnectingButtonProducer
        )

        // perform "remove peripheral" behavior
        showRemovePeripheral <~ closeOverlayProducer(type: RemovePeripheralViewController.self)

        // show and hide "connect health" overlay
        showConnectHealthKit <~ activateOverlayProducer(
            type: OpenHealthViewController.self,
            activateProducer: peripheralsViewController.connectHealthProducer
        )

        peripheralsViewController.removeButtonProducer.startWithValues({ [weak self] peripheral in
            self?.showRemovePeripheral.value = true

            if !peripheral.isConnected
            {
                services.peripherals.remove(peripheral)
            }
        })
    }
}

extension ConnectViewController
{
    // MARK: - Activating Overlays

    /**
     Returns a producer that will yield a boolean to close an overlay view controller.

     - parameter type: The overlay view controller type.
     */
    fileprivate func closeOverlayProducer<Overlay: ClosableConnectOverlay>(type: Overlay.Type)
        -> SignalProducer<Bool, NoError>
    {
        return container.childViewController.producer
            .observe(on: QueueScheduler.main) // break deadlock on closing overlay view
            .map({ $0 as? Overlay })
            .flatMapOptional(.latest, transform: { $0.closeProducer })
            .skipNil()
            .map({ _ in false })
    }

    /**
     Returns a producer that will yield booleans to activate and deactivate an overlay view controller.

     - parameter type:             The overlay view controller type.
     - parameter activateProducer: A producer that should yield a value when the overlay should become visible.
     */
    fileprivate func activateOverlayProducer<Overlay: ClosableConnectOverlay>
        (type: Overlay.Type, activateProducer: SignalProducer<(), NoError>)
        -> SignalProducer<Bool, NoError>
    {
        return SignalProducer.merge(
            activateProducer.map({ _ in true }),
            closeOverlayProducer(type: type)
        )
    }
}

extension ConnectViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(
        containerViewController: ContainerViewController,
        animationControllerForTransitionFromViewController fromViewController: UIViewController?,
        toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        if fromViewController != nil && toViewController != nil
        {
            return CrossDissolveTransitionController(duration: 0.25)
        }
        else
        {
            return nil
        }
    }
}

extension ConnectViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        container.tabBarViewControllerDidTapSelectedItem()
    }
}

/// A protocol for overlay child view controllers of `ConnectViewController` that offer a "Close" interface.
protocol ClosableConnectOverlay
{
    var closeProducer: SignalProducer<(), NoError> { get }
}
