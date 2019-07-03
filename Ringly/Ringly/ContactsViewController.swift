import AddressBookUI
import ContactsUI
import PureLayout
import ReactiveSwift
import Result
import RinglyExtensions

final class ContactsViewController: ConfigurationsViewController
{
    // MARK: - Display Configurations
    fileprivate let configurations = MutableProperty([ContactConfiguration]())
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // register cell classes
        tableView.registerCellType(ContactConfigurationCell.self)
        tableView.registerCellType(CheckboxCell.self)
        
        // table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none

        // sort contacts for display
        configurations <~ services.contacts.configurations.producer.map({ configurations in
            configurations.sorted(by: { $0.displayName < $1.displayName })
        })
        
        // reload automatically when contacts change
        configurations.producer.startWithValues({ [weak self] _ in self?.reloadTableView() })

        // topbar setup
        navigationBar.title.value = .text(trUpper(.contacts))

        // show the "add a contact" view if we have no contacts
        onboardingViewController <~ configurations.producer
            .map({ $0.count == 0 })
            .skipRepeats()
            .map({ $0 ? .some(ContactsOnboardingViewController()) : .none })

        // allow users to add contacts
        actionProducer.startWithValues({ [weak self] _ in self?.addAContactAction() })
    }
    
    // MARK: - Actions
    fileprivate func addAContactAction()
    {
        let permissionProducer = SignalProducer<(), NSError> { sink, disposable in
            CNContactStore().requestAccess(for: .contacts, completionHandler: { granted, error in
                if granted
                {
                    sink.sendCompleted()
                }
                else
                {
                    sink.send(error: error as? NSError ?? ContactsError.unknown as NSError)
                }
            })
        }

        let tooManyError: SignalProducer<(), NSError> = services.contacts.configurations.value.count > 31
            ? SignalProducer(error: NSError(domain: "Contacts", code: 32, userInfo: [
                NSLocalizedDescriptionKey: tr(.contactsTooManyText),
                NSLocalizedFailureReasonErrorKey: tr(.contactsTooManyDetailText)
            ]))
            : SignalProducer.empty
        
        permissionProducer.then(tooManyError)
            .observe(on: QueueScheduler.main)
            .on(failed: { [weak self] error in self?.presentAddContactError(error) }, completed: { [weak self] in
                let picker = NoStatusBarContactPickerViewController()
                picker.delegate = self
                picker.transitioningDelegate = SlideTransitionController.sharedDelegate.vertical
                self?.present(picker, animated: true, completion: nil)
            })
            .start()
    }


    /// Presents an error encountered after the user taps the "add contact" button.
    ///
    /// - Parameter error: The error.
    fileprivate func presentAddContactError(_ error: NSError)
    {
        if error.domain == "Contacts"
        {
            services.analytics.track(ExceededContactLimitEvent())
        }

        if error.domain == CNErrorDomain && error.code == CNError.authorizationDenied.rawValue
        {
            let bundle = Bundle.main
            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Ringly"
            let message = tr(.contactsAddAllow(name))
            AlertViewController(openSettingsDetailText: message).present(above: self)
        }
        else
        {
            presentError(error)
        }
    }

    fileprivate weak var deletingContactCell: ContactConfigurationCell?

    // MARK: - Transition Override
    override func containerViewController(containerViewController: ContainerViewController,
                                          animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                          toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        // don't show a transition when moving away from onboarding, we already have a modal transition
        return toViewController != nil
            ? super.containerViewController(
                containerViewController: containerViewController,
                animationControllerForTransitionFromViewController: fromViewController,
                toViewController: toViewController
            )
            : nil
    }
}

extension ContactsViewController: UITableViewDataSource
{
    // MARK: - Table View Data Source
    fileprivate enum Section: Int
    {
        case checkboxes = 0
        case contacts = 1
        case invalid = 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch Section(rawValue: section) ?? .invalid
        {
        case .checkboxes:
            return 2
        case .contacts:
            return configurations.value.count
        case .invalid:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        switch Section(rawValue: indexPath.section) ?? .invalid
        {
        case .checkboxes:
            let cell = tableView.dequeueCellOfType(CheckboxCell.self, forIndexPath: indexPath)
            let cellIsForInnerRingOn = indexPath.row == 1
            
            // update cell when inner ring setting changes
            let checkedProducer = cellIsForInnerRingOn
                ? services.preferences.innerRing.producer
                : services.preferences.innerRing.producer.not
            
            checkedProducer
                .take(until: SignalProducer(cell.reactive.prepareForReuse))
                .startWithValues({ [weak cell] checked in cell?.checked = checked })
            
            // format cell appearance
            cell.caption = tr(cellIsForInnerRingOn ? .contactsInnerRingOn : .contactsInnerRingOff)
            
            return cell

        case .contacts:
            let cell = tableView.dequeueCellOfType(ContactConfigurationCell.self, forIndexPath: indexPath)
            
            // update cell information
            cell.contactConfiguration.value = configurations.value[indexPath.row]
            cell.delegate = self
            
            // ensure we only have one "deleting" cell at a time
            cell.deleting.producer
                .skip(first: 1)
                .skipRepeats(==)
                .take(until: SignalProducer(cell.reactive.prepareForReuse))
                .startWithValues({ [weak self, weak cell] deleting in
                    if deleting
                    {
                        if let otherCell = self?.deletingContactCell
                        {
                            UIView.animate(withDuration: 0.25, animations: {
                                otherCell.deleting.value = false
                                otherCell.layoutIfNeeded()
                            })
                        }
                        
                        self?.deletingContactCell = cell
                    }
                    else
                    {
                        if self?.deletingContactCell == cell && cell != nil
                        {
                            self?.deletingContactCell = nil
                        }
                    }
                })
            
            return cell
        case .invalid:
            return UITableViewCell()
        }
    }
}

extension ContactsViewController: UITableViewDelegate
{
    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        return indexPath.section == Section.checkboxes.rawValue
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let enableInner = indexPath.row == 1
        
        if enableInner != services.preferences.innerRing.value
        {
            UIView.animate(withDuration: 0.25, animations: {
                self.services.preferences.innerRing.value = enableInner
            })

            services.analytics.track(AnalyticsEvent.changedSetting(setting: .innerRing, value: enableInner))
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ContactConfigurationCellDelegate
extension ContactsViewController: ContactConfigurationCellDelegate
{
    func contactConfigurationCellDeleteContact(_ cell: ContactConfigurationCell)
    {
        if let indexPath = tableView.indexPath(for: cell)
        {
            suspendReloadTableViewFor {
                services.contacts.removeConfiguration(configurations.value[indexPath.row])
                
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
            
            // if inner ring is enabled and this was the last contact, disable it
            if services.preferences.innerRing.value && services.contacts.configurations.value.count == 0
            {
                services.preferences.innerRing.value = false
            }
            
            // track in analytics
            services.analytics.track(AnalyticsEvent.disabledContact)
        }
    }
    
    func contactConfigurationCell(_ cell: ContactConfigurationCell,
                                  selectedColor color: DefaultColor,
                                  withMethod method: ColorSliderViewSelectionMethod)
    {
        if let index = tableView.indexPath(for: cell)?.row
        {
            // display the color on a connected peripheral
            display(demo: PeripheralNotification(color: DefaultColorToLEDColor(color), colorFadeDuration: 5))

            // change contact color
            suspendReloadTableViewFor {
                let identifier = self.configurations.value[index].identifier

                services.contacts.modify(
                    identifier: identifier,
                    with: { ContactConfiguration(dataSource: $0.dataSource, color: color) }
                )

                // after the previous call, the value of `configurations` will be automatically updated by the binding
                // created in `viewDidLoad`, so the version with the new color is now present
                let configuration = self.configurations.value[index]
                cell.contactConfiguration.value = configuration

                // track in analytics
                self.services.analytics.track(ContactChangedEvent(configuration: configuration, method: method))
            }
        }
    }
}

// MARK: - CNContactPickerDelegate
extension ContactsViewController: CNContactPickerDelegate
{
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact)
    {
        switch services.contacts.addConfiguration(from: contact)
        {
        case .success:
            break
        case .failure(let error):
            self.presentError(error as NSError)
        }
    }
}

private final class NoStatusBarContactPickerViewController: CNContactPickerViewController
{
    override var prefersStatusBarHidden : Bool
    {
        return true
    }
}
