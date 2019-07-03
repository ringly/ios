import PureLayout
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit

final class AddPeripheralViewController: ServicesViewController
{
    // MARK: - Paired

    /// A backing property for `pairedProducer`.
    fileprivate let pairedProperty = MutableProperty<PeripheralReference?>(nil)

    /// Sends the new peripheral reference when a new peripheral is paired.
    var pairedProducer: SignalProducer<PeripheralReference, NoError>
    {
        return pairedProperty.producer.skipNil()
    }

    // MARK: - View Loading
    fileprivate let addPeripheralView = AddPeripheralView(frame: CGRect.zero)

    override func loadView()
    {
        self.view = addPeripheralView
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = tr(.peripheralsAddJewelry)

        // register cell types
        addPeripheralView.tableView.registerCellType(AddPeripheralCell.self)

        // update current state of view
        let discoveryProducer = services.peripherals.central.reactive.discovery.take(until: reactive.lifetime.ended)
        let pairingProducer = pairingWithPeripheral.producer
        let restartingProducer = services.preferences.deviceInRecovery.producer

        SignalProducer.combineLatest(pairingProducer, discoveryProducer, haveTimedOut.producer, haveErroredOut.producer, restartingProducer)
            .map({ pairingOrPaired, maybeDiscovery, haveTimedOut, haveErroredOut, restarting -> AddPeripheralView.State in
                if restarting
                {
                    return .activityNotCancellable
                }
                else if let discovery = maybeDiscovery
                {
                    if discovery.peripherals.count + discovery.recoveryPeripherals.count > 1
                    {
                        return .table
                    }
                    else
                    {
                        return .activityCancellable
                    }
                }
                else if pairingOrPaired
                {
                    return .activityNotCancellable
                }
                else if haveErroredOut
                {
                    return .connectError
                }
                else if haveTimedOut
                {
                    return .connectTimeout
                }
                else
                {
                    return .activityNotCancellable
                }
            })
            .skipRepeats()
            .start(animationDuration: 0.33, action: { [weak addPeripheralView] state in
                addPeripheralView?.state.value = state
                addPeripheralView?.layoutIfInWindowAndNeeded()
            })

        // reload table view during discovery
        addPeripheralView.tableView.dataSource = self
        addPeripheralView.tableView.delegate = self

        discoveryProducer.skip(first: 1).startWithValues({ [weak addPeripheralView] _ in
            addPeripheralView?.tableView.reloadData()
        })
        
        discoveryProducer.skipNil().startWithValues({ discovery in
            if let recovery = discovery.recoveryPeripherals.first, discovery.recoveryPeripherals.count == 1,
                !self.pairingWithPeripheral.value {
                    DispatchQueue.main.async(execute: {
                        self.presentRecoveryWithPeripheral(recovery)
                    })
            }
        })

        // when discovery begins, automatically connect a peripheral if only one is found within two seconds
        discoveryProducer
            .flatMapOptional(.latest, transform: { discovery -> SignalProducer<Either<RLYPeripheral, RLYRecoveryPeripheral>, NoError> in
                if let either = (discovery.peripherals.first.map({ Either.left($0) })
                    ?? discovery.recoveryPeripherals.first.map({ Either.right($0) })), discovery.peripherals.count + discovery.recoveryPeripherals.count == 1
                {
                    let date = discovery.startDate.addingTimeInterval(2)
                    return timerUntil(date: date, on: QueueScheduler.main)
                        .map({ _ in either })
                }
                else
                {
                    return SignalProducer.empty
                }
            })
            .skipNil()
            .startWithValues({ [weak self] either in
                // this is necessary to prevent a lockup
                if let pairing = self?.pairingWithPeripheral.value, !pairing {
                    DispatchQueue.main.async(execute: {
                        switch either
                        {
                        case .left(let peripheral):
                            self?.connectToPeripheral(peripheral)
                        case .right(let peripheral):
                            self?.presentRecoveryWithPeripheral(peripheral)
                        }
                    })
                }
            })

        // automatically time out discovery if connection does not begin after 10 seconds
        discoveryProducer
            .flatMapOptional(.latest, transform: { discovery -> SignalProducer<(), NoError> in
                if discovery.peripherals.count + discovery.recoveryPeripherals.count == 0
                {
                    let date = discovery.startDate.addingTimeInterval(10)
                    return timerUntil(date: date, on: QueueScheduler.main).void
                }
                else
                {
                    return SignalProducer.empty
                }
            })
            .skipNil()
            .startWithValues({ [weak self] _ in
                // this is necessary to prevent a lockup
                DispatchQueue.main.async(execute: { 
                    self?.haveTimedOut.value = true
                    self?.services.peripherals.central.stopDiscoveringPeripherals()
                })
            })

        // add actions for controls
        SignalProducer(addPeripheralView.connect.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            guard let strong = self else { return }

            let peripherals = strong.services.peripherals
            let central = peripherals.central

            if central.isPoweredOff
            {
                central.promptToPowerOnBluetooth()
            }
            else
            {
                // dismiss the error message if visible
                strong.haveErroredOut.value = false

                // retrieve the current identifiers we have for referenced peripherals
                let currentIdentifiers = Set(peripherals.references.value.map({ $0.identifier }))

                // filter out already referenced peripherals from the currently connected peripherals
                let nonReferencedPeripherals = central.retrieveConnectedPeripherals()
                    .filter({ !currentIdentifiers.contains($0.identifier) })

                // if we have any connected peripherals that are not referenced, we should just add those
                if nonReferencedPeripherals.count > 0
                {
                    nonReferencedPeripherals.forEach({ peripheral in
                        // it is necessary to connect to the peripheral for Core Bluetooth to recognize that it is
                        // connected, even though we retrieved the connected peripherals
                        central.connect(to: peripheral)
                        peripherals.register(peripheral: peripheral)
                    })
                }
                else // otherwise, we need to discover new peripherals
                {
                    central.startDiscoveringPeripherals()
                }
            }
        })

        SignalProducer(addPeripheralView.logout.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak services] _ in
            services?.api.logout()
        })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        services.peripherals.central.startDiscoveringPeripherals()
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        if services.peripherals.central.discovery != nil
        {
            services.peripherals.central.stopDiscoveringPeripherals()
        }
    }

    // MARK: - State

    /// Whether or not the last attempt at discovering a peripheral timed out.
    fileprivate let haveTimedOut = MutableProperty(false)

    /// Whether or not the last attempt to connect to a peripheral errored out.
    fileprivate let haveErroredOut = MutableProperty(false)

    /// Whether or not we are currently pairing with a peripheral.
    fileprivate let pairingWithPeripheral = MutableProperty(false)
}

extension AddPeripheralViewController
{
    fileprivate func connectToPeripheral(_ peripheral: RLYPeripheral)
    {
        pairingWithPeripheral.value = true

        pairedProperty <~ services.peripherals.pair(with: peripheral)
            .on(
                failed: { [weak self] _ in
                    self?.haveErroredOut.value = true
                },
                terminated: { [weak self] in
                    self?.pairingWithPeripheral.value = false
                }
            )
            .flatMapError({ _ in SignalProducer.empty })
            .map({ $0 })

        services.peripherals.central.stopDiscoveringPeripherals()
    }

    fileprivate func presentRecoveryWithPeripheral(_ peripheral: RLYRecoveryPeripheral)
    {
        // ensure alert only happens once
        self.services.preferences.deviceInRecovery.value = false
        
        if let hardware = peripheral.hardwareVersion?.value
        {
            pairingWithPeripheral.value = true
            
            let DFU = DFUViewController(services: services)

            DFU.configure(
                mode: .recovery(peripheralIdentifier: peripheral.peripheral.identifier, hardwareVersion: hardware),
                packageSource: .latestForHardware(version: hardware, APIService: services.api)
            )

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                self.view.window?.rootViewController?.present(DFU, animated: true, completion: nil)
            })
            
            DFU.completion = { [weak self] controller in
                controller.dismiss(animated: true, completion: nil)
                self?.pairingWithPeripheral.value = false
                if let parent = self?.parent as? UINavigationController {
                    parent.popViewController(animated: true)
                }
            }
            
            DFU.failed = { [weak self] controller in
                controller.dismiss(animated: true, completion: nil)
                self?.pairingWithPeripheral.value = false
            }
        }
        else
        {
            presentAlert(title: "Error", message: "Unsupported hardware version")
        }
    }
}

extension AddPeripheralViewController: UITableViewDataSource
{
    // MARK: - Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return services.peripherals.central.discovery?.recoveryPeripherals.count ?? 0
        }
        else
        {
            return services.peripherals.central.discovery?.peripherals.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueCellOfType(AddPeripheralCell.self, forIndexPath: indexPath)

        if indexPath.section == 0
        {
            let name = services.peripherals.central.discovery?.recoveryPeripherals[indexPath.row].peripheral.name
            cell.labelContent.value = (name: name ?? "Peripheral", lastFour: "Recovery Mode")
        }
        else if let peripheral = services.peripherals.central.discovery?.peripherals[indexPath.row]
        {
            let nameProducer = peripheral.reactive.style.map({ RLYPeripheralStyleName($0) ?? "RINGLY" })

            cell.labelContent <~ nameProducer.combineLatest(with: peripheral.reactive.lastFourMAC)
                .map(unwrap)
                .take(until: SignalProducer(cell.reactive.prepareForReuse))

            cell.styleContent <~ peripheral.reactive.style.map({ $0 }).take(until: SignalProducer(cell.reactive.prepareForReuse))
        }

        return cell
    }
}

extension AddPeripheralViewController: UITableViewDelegate
{
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.setContentOffset(CGPoint.zero, animated: true)

        guard let discovery = services.peripherals.central.discovery else { return }

        if indexPath.section == 0
        {
            presentRecoveryWithPeripheral(discovery.recoveryPeripherals[indexPath.row])
        }
        else
        {
            connectToPeripheral(discovery.peripherals[indexPath.row])
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        addPeripheralView.tableMaskView.contentOffset.value = scrollView.contentOffset.y
    }
}

// MARK: - View Classes
private final class AddPeripheralView: UIView
{
    // MARK: - Buttons
    let connect = ButtonControl.newAutoLayout()
    let logout = ButtonControl.newAutoLayout()

    // MARK: - Table View
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    let tableMaskView = TopGradientMaskView(frame: .zero)

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add top content views
        let logoContainer = UIView.newAutoLayout()
        addSubview(logoContainer)

        let errorView = AddPeripheralErrorView.newAutoLayout()
        addSubview(errorView)

        let timeout = AddPeripheralTimeoutView.newAutoLayout()
        addSubview(timeout)

        let activity = DiamondActivityIndicator.newAutoLayout()
        addSubview(activity)

        // this container is necessary for masking, as the mask applies to the table view in a scrolling sense
        let tableViewContainer = UIView.newAutoLayout()
        addSubview(tableViewContainer)
//        tableViewContainer.maskView = tableMaskView

        // table view setup
        tableView.backgroundColor = .clear
        tableView.indicatorStyle = .white
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor(white: 1, alpha: 0.33)
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.rowHeight = 78
        tableViewContainer.addSubview(tableView)

        // button control formatting
        let buttonControls = [connect, logout]

        connect.title = tr(.connect)
        logout.title = tr(.logOut)

        buttonControls.forEach(addSubview)

        // layout - logo view
        logoContainer.autoPinEdgeToSuperview(edge: .leading)
        logoContainer.autoPinEdgeToSuperview(edge: .trailing)
        logoContainer.autoPinEdgeToSuperview(edge: .top)
        logoContainer.autoPin(edge: .bottom, to: .top, of: connect)

        // layout - activity indicator
        activity.autoCenterInSuperview()
        activity.constrainToDefaultSize()

        // layout - table view
        tableViewContainer.autoPinEdgesToSuperviewEdges()
        tableView.autoPinEdgesToSuperviewEdges()

        // layout - timeout
        timeout.autoPinEdgeToSuperview(edge: .top, inset: 60)
        timeout.autoPin(edge: .bottom, to: .top, of: connect)
        timeout.autoFloatInSuperview(alignedTo: .vertical, inset: 10)
        timeout.autoSet(dimension: .width, to: 282, relation: .lessThanOrEqual)

        // layout - buttons
        buttonControls.forEach({ button in
            button.autoAlignAxis(toSuperviewAxis: .vertical)
            button.autoSetDimensions(to: CGSize(width: 258, height: 50))
        })

        let bottomInset: CGFloat = 60

        connect.autoPinEdgeToSuperview(edge: .bottom, inset: bottomInset)

        let logoutBottom = logout.autoPinEdgeToSuperview(edge: .bottom, inset: bottomInset)
        connect.autoPin(edge: .bottom, to: .top, of: logout, offset: -15)

        // layout - connect error
        errorView.autoFloatInSuperview(alignedTo: .vertical)
        errorView.autoPinEdgeToSuperview(edge: .top)
        errorView.autoPin(edge: .bottom, to: .top, of: connect)
        errorView.autoSet(dimension: .width, to: 280, relation: .lessThanOrEqual)

        // update appearance when state changes
        state.producer.startWithValues({ [weak self] state in
            guard let strong = self else { return }

            // update visibility of interface elements
            let outTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            strong.connect.conditionallyEnable(state == .connectError || state == .connectTimeout)

            activity.alpha = state == .activityCancellable || state == .activityNotCancellable ? 1 : 0
            strong.tableView.conditionallyEnable(state == .table, transform: CGAffineTransform.identity)

            let showError = state == .connectError
            errorView.conditionallyEnable(showError, transform: outTransform)

            let showTimeout = state == .connectTimeout
            timeout.conditionallyEnable(showTimeout, transform: outTransform)
            strong.logout.conditionallyEnable(showTimeout)

            // alter layout constraints
            NSLayoutConstraint.conditionallyActivateConstraints([(logoutBottom, state == .connectTimeout)])
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

    // MARK: - Layout
    fileprivate override func layoutSubviews()
    {
        super.layoutSubviews()
        tableMaskView.frame = tableView.bounds
    }

    // MARK: - State
    let state = MutableProperty(State.activityCancellable)

    enum State
    {
        case activityCancellable
        case activityNotCancellable
        case table
        case connectError
        case connectTimeout
    }
}

private final class AddPeripheralTimeoutView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let logo = UIImageView.newAutoLayout()
        logo.image = UIImage(asset: .authenticationLogo)
        logo.contentMode = .scaleAspectFit
        addSubview(logo)

        let labels = AddPeripheralTimeoutLabelsView.newAutoLayout()
        addSubview(labels)

        logo.autoPinEdgeToSuperview(edge: .top)
        logo.autoFloatInSuperview(alignedTo: .vertical)

        labels.autoPin(edge: .top, to: .bottom, of: logo)
        labels.autoPinEdgeToSuperview(edge: .bottom)
        labels.autoFloatInSuperview(alignedTo: .vertical)

        labels.title.autoPin(edge: .top, to: .bottom, of: logo, offset: 10, relation: .greaterThanOrEqual)
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

private final class AddPeripheralTimeoutLabelsView: UIView
{
    // MARK: - Subviews
    let title = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add vertical centering container
        let container = UIView.newAutoLayout()
        addSubview(container)

        // add labels
        title.numberOfLines = 3
        title.textColor = UIColor.white

        let font = UIFont.gothamBook(18)
        title.attributedText = ["OH NO! WE CAN'T\n", "FIND A RINGLY\n", "NEARBY"].map({ string in
            font.track(.controlsTracking, string)
        }).join().attributedString

        container.addSubview(title)

        let body = UILabel.newAutoLayout()
        body.numberOfLines = 0
        body.textColor = UIColor.white

        body.attributedText = UIFont.gothamBook(15).track(30, tr(.peripheralsMakeSureCharged)).attributes(
            paragraphStyle: NSParagraphStyle.with(alignment: .center, lineSpacing: 5)
        )

        container.addSubview(body)

        // layout
        container.autoFloatInSuperview()

        [(title, ALEdge.top), (body, .bottom)].forEach({ label, edge in
            label.autoPinEdgeToSuperview(edge: edge)
            label.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
            label.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
            label.autoAlignAxis(toSuperviewAxis: .vertical)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        })

        body.autoPin(edge: .top, to: .bottom, of: title, offset: 28)
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

private final class AddPeripheralErrorView: UIView
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        let container = UIView.newAutoLayout()
        addSubview(container)

        // the ring box displaying an arrow
        let ringBox = PeripheralBoxView.newAutoLayout()
        ringBox.playingArrowAnimation.value = true
        ringBox.peripheralBackgroundColor = UIColor(red: 0.5875, green: 0.5875, blue: 0.8147, alpha: 1)
        container.addSubview(ringBox)

        // a label describing the error
        let label = UILabel.newAutoLayout()
        label.numberOfLines = 0
        label.attributedText = trUpper(.peripheralsPlaceInCharger).attributes(
            color: .white,
            font: .gothamBook(14),
            paragraphStyle: .with(alignment: .center, lineSpacing: 3),
            tracking: 114
        )

        container.addSubview(label)

        // layout
        container.autoFloatInSuperview()

        ringBox.autoAlignAxis(toSuperviewAxis: .vertical)

        [ALEdge.leading, .trailing, .bottom].forEach({ edge in
            ringBox.autoPinEdgeToSuperview(edge: edge, inset: 0, relation: .greaterThanOrEqual)
        })

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            ringBox.autoPin(edge: .top, to: .bottom, of: label, offset: 38)
        })

        ringBox.autoPin(edge: .top, to: .bottom, of: label, offset: 16, relation: .greaterThanOrEqual)

        label.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .bottom)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
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

// MARK: - UIView Extensions
extension UIView
{
    fileprivate func conditionallyEnable(_ conditional: Bool, transform: CGAffineTransform = CGAffineTransform.identity)
    {
        self.isUserInteractionEnabled = conditional
        self.alpha = conditional ? 1 : 0
        self.transform = conditional ? CGAffineTransform.identity : transform
    }
}
