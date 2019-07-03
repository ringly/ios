import ReactiveSwift
import Result
import RinglyAPI
import RinglyExtensions
import RinglyKit

/// Displays an interface for editing the current application settings, stored in `services.applications`.
final class ApplicationsViewController: ConfigurationsViewController
{
    // MARK: - State
    
    /// Whether or not the applications are being edited.
    fileprivate let editingProperty = MutableProperty(false)

    /// A producer for the view controller's current editing state.
    var editingProducer: SignalProducer<Bool, NoError>
    {
        return editingProperty.producer
    }
    
    /// The current configurations displayed by the view controller.
    fileprivate let configurations = MutableProperty<[ApplicationConfiguration]>([])
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let preferences = services.preferences

        navigationBar.title.value = .text(trUpper(.alerts))
        navigationBar.showBouncingArrow <~ preferences.applicationsOnboardingState.producer.map({ $0 == .prompt })

        // table view setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCellType(ApplicationConfigurationCell.self)
        tableView.registerCellType(ApplicationsEditPromptCell.self)
        
        // edit button
        editingProperty.producer.startWithValues({ [weak tableView] in tableView?.allowsSelection = $0 })
        editingProducer.producer.start(
            animationDuration: 0.25,
            action: { [weak navigationBar] in
                navigationBar?.actionButtonTransform = $0
                    ? CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
                    : CGAffineTransform.identity
            }
        )

        // bind configurations
        configurations <~ SignalProducer.combineLatest(
                editingProperty.producer,
                services.applications.installedConfigurations.producer,
                services.applications.activatedConfigurations.producer
            )
            .map({ editing, installed, activated in
                return editing ? installed : activated
            })
        
        // reload automatically whenever configurations change
        configurations.producer.startWithValues({ [weak self] _ in self?.reloadTableView() })

        // show overlay controller before onboarding has been completed, or when there are zero configurations
        let haveActivatedConfigurations = services.applications.activatedConfigurations.producer.map({ $0.count > 0 })

        onboardingViewController <~ preferences.applicationsOnboardingState.producer.map({ $0 != .overlay })
            .and(haveActivatedConfigurations.or(editingProperty.producer))
            .skipRepeats()
            .map({ $0 ? .none : .some(ApplicationsOnboardingViewController()) })

        // complete applications onboarding and edit when action button is tapped
        actionProducer.startWithValues({ [weak self] action in
            guard let strong = self else { return }

            if action == .navigation
            {
                preferences.applicationsOnboardingState.value = .complete
                strong.reloadTableView()
                strong.setEditing(!strong.isEditing, animated: true)
            }
            else
            {
                preferences.applicationsOnboardingState.value = .prompt
            }
        })
    }
    
    // MARK: - Editing
    override func setEditing(_ editing: Bool, animated: Bool)
    {
        let change = self.isEditing != editing
        
        super.setEditing(editing, animated: animated)
        
        suspendReloadTableViewFor {
            if change
            {
                // find the index paths we need to add or remove
                let paths = self.services.applications.installedConfigurations.value
                    .enumerated()
                    .filter({ _, configuration in !configuration.activated })
                    .map({ index, _ in IndexPath(row: index, section: 0) })
                
                // reset current cells
                UIView.animate(if: animated, duration: 0.25, animations: {
                    for cell in self.tableView.visibleCells
                    {
                        if let configurationCell = cell as? ApplicationConfigurationCell
                        {
                            configurationCell.collapseVibrationChooser()

                            if configurationCell.configuration.value?.activated ?? false
                            {
                                configurationCell.inSelectionMode.value = editing
                            }
                        }
                    }
                })

                self.editingProperty.value = editing

                // add or remove non-activated cells
                if animated
                {
                    tableView.beginUpdates()
                    
                    if editing
                    {
                        tableView.insertRows(at: paths, with: .fade)
                    }
                    else
                    {
                        tableView.deleteRows(at: paths, with: .fade)
                    }
                    
                    self.tableView.endUpdates()
                }
                else
                {
                    tableView.reloadData()
                }
            }
        }
    }
}

extension ApplicationsViewController: UITableViewDataSource
{
    // MARK: - Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return section == 0
            ? configurations.value.count
            : (services.preferences.applicationsOnboardingState.value != .complete ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.section == 0
        {
            let cell = tableView.dequeueCellOfType(ApplicationConfigurationCell.self, forIndexPath: indexPath)
            cell.delegate = self
            cell.configuration.value = configurations.value[indexPath.row]
            cell.inSelectionMode.value = self.isEditing

            return cell
        }
        else
        {
            return tableView.dequeueCellOfType(ApplicationsEditPromptCell.self, forIndexPath: indexPath)
        }
    }
}

extension ApplicationsViewController: UITableViewDelegate
{
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let
            cell = tableView.cellForRow(at: indexPath) as? ApplicationConfigurationCell,
            let current = cell.configuration.value
        else {
            return
        }
        
        suspendReloadTableViewFor {
            let applications = services.applications

            let modified = applications.modify(identifier: current.identifier, with: {
                ApplicationConfiguration(
                    application: $0.application,
                    color: $0.color,
                    vibration: $0.vibration,
                    activated: !$0.activated
                )
            })

            if let new = modified
            {
                UIView.animate(withDuration: 0.25, animations: {
                    cell.configuration.value = new
                })

                self.sendConfigurationChangedAnalytics(new, method: .enabled)
            }
        }

        services.engagementNotifications.cancel(.addRemoveApplications)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return indexPath.section == 0 ? tableView.rowHeight : 170
    }
}

extension ApplicationsViewController: ApplicationConfigurationCellDelegate
{
    func applicationConfigurationCell(_ cell: ApplicationConfigurationCell,
                                      didSetColor color: DefaultColor,
                                      withMethod method: ColorSliderViewSelectionMethod)
    {
        if let current = cell.configuration.value
        {
            // display the color on a connected peripheral
            display(demo: PeripheralNotification(color: DefaultColorToLEDColor(color), colorFadeDuration: 5))
            
            // change the color
            suspendReloadTableViewFor {
                let applications = services.applications

                let modified = applications.modify(identifier: current.identifier, with: {
                    ApplicationConfiguration(
                        application: $0.application,
                        color: color,
                        vibration: $0.vibration,
                        activated: $0.activated
                    )
                })

                if let new = modified
                {
                    cell.configuration.value = new
                    sendConfigurationChangedAnalytics(new, method: .color(method))
                }
            }

            services.engagementNotifications.cancel(.editApplicationBehavior)
        }
    }
    
    func applicationConfigurationCell(_ cell: ApplicationConfigurationCell, didSetVibration vibration: RLYVibration)
    {
        if let current = cell.configuration.value
        {
            // play the vibration on a connected peripheral
            display(demo: PeripheralNotification(
                vibration: vibration,
                color: DefaultColorToLEDColor(current.color)
            ))
            
            // change the vibration
            suspendReloadTableViewFor {
                let applications = services.applications

                let modified = applications.modify(identifier: current.identifier, with: {
                    ApplicationConfiguration(
                        application: $0.application,
                        color: $0.color,
                        vibration: vibration,
                        activated: $0.activated
                    )
                })

                if let new = modified
                {
                    cell.configuration.value = new
                    sendConfigurationChangedAnalytics(new, method: .vibration)
                }
            }

            services.engagementNotifications.cancel(.editApplicationBehavior)
        }
    }
    
    fileprivate func sendConfigurationChangedAnalytics(_ configuration: ApplicationConfiguration, method: ApplicationChangedMethod)
    {
        services.analytics.track(ApplicationChangedEvent(configuration: configuration, method: method))
    }
}

/// The states available for applications onboarding.
enum ApplicationsOnboardingState: Int
{
    /// A full overlay is shown atop the applications view controller.
    case overlay = 0

    /// Onboarding is complete.
    case complete = 1

    /// An edit prompt is displayed in the normal applications view controller interface.
    case prompt = 2
}

extension ApplicationsOnboardingState: Coding
{
    typealias Encoded = Any

    static func decode(_ encoded: Any) throws -> ApplicationsOnboardingState
    {
        if let bool = encoded as? Bool
        {
            return bool ? .complete : .overlay
        }
        else if let state = (encoded as? RawValue).flatMap(ApplicationsOnboardingState.init)
        {
            return state
        }
        else
        {
            throw DecodeAnyError()
        }
    }

    var encoded: Any { return rawValue }
}
