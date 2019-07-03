import HealthKit
import ReactiveSwift
import UIKit
import enum Result.NoError

final class MindfulMinuteGoalViewController: ServicesViewController
{
    // MARK: - Stack Views
    
    /// The root stack view, which combines `filledPickersStack`, `emptyPickersStack`, and other elements.
    fileprivate let rootStack = UIStackView.newAutoLayout()
    
    // MARK: - Picker Views
    /// The picker view for setting the user's mindfulness goal.
    fileprivate let mindfulnessGoalPicker = SettingsPickerView.newAutoLayout()
    
    // MARK: - Units
    fileprivate let units = Locale.current.preferredUnits
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // stack view layout settings
        [rootStack].forEach({ stack in
            stack.alignment = .fill
            stack.axis = .vertical
        })
        
        // space elements of stack views
        [rootStack].forEach({ $0.spacing = 45 })
        
        // add the root stack view - which is inset on the vertical axis from the root view
        view.addSubview(rootStack)
        rootStack.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: 43, left: 0, bottom: 58, right: 0))
        
        // step goal picker is always visible in the filled stack, since it cannot be skipped or nil
        rootStack.addArrangedSubview(mindfulnessGoalPicker)
        
        mindfulnessGoalPicker.title = "MINUTES"

    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let goalFormatter = NumberFormatter()
        goalFormatter.usesGroupingSeparator = true
        goalFormatter.numberStyle = .decimal
        
        // allow user to adjust steps goal
        let preferences = services.preferences
        
        mindfulnessGoalPicker.actionsProducer.startWithValues({ action in
            let offset = 1 * (action == .increase ? 1 : -1)
            
            preferences.activityTrackingMindfulnessGoal.pureModify({ current in
                min(30, max(5, current + offset))
            })
        })
        
        // format and display the steps goal
        let stepsFormatter = NumberFormatter()
        stepsFormatter.usesGroupingSeparator = true
        stepsFormatter.numberStyle = .decimal
        
        mindfulnessGoalPicker.quantityComponents <~ services.preferences.activityTrackingMindfulnessGoal.producer.map({ minutes in
            [UnitStringComponent(string: stepsFormatter.string(from: NSNumber(value: minutes)) ?? String(minutes), part: .value)]
        })
        
    }

    /// Presents a body data selection controller.
    ///
    /// - parameter controller: The controller to display.
    /// - parameter producer:   A producer for a confirmed value.
    /// - parameter property:   The property to update with the confirmed value.
    fileprivate func present<Value>(controller: UIViewController,
                             producer: SignalProducer<Value, NoError>,
                             property: MutableProperty<Skippable<Value>?>)
    {
        producer.startWithValues({ [weak self] value in
            property.value = .Value(value)
            _ = self?.navigationController?.popViewController(animated: true)
        })
        
        let bodyData = PreferencesBodyDataViewController()
        bodyData.childViewController = controller
        navigationController?.pushViewController(bodyData, animated: true)
    }
}
