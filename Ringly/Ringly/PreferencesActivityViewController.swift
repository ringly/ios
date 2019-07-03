import HealthKit
import ReactiveSwift
import UIKit
import enum Result.NoError

final class PreferencesActivityViewController: ServicesViewController
{
    // MARK: - Stack Views

    /// The root stack view, which combines `filledPickersStack`, `emptyPickersStack`, and other elements.
    fileprivate let rootStack = UIStackView.newAutoLayout()

    /// A stack view for the _filled_ picker views - those that the user has provided an initial value for.
    fileprivate let filledPickersStack = UIStackView.newAutoLayout()

    /// A stack view for the _empty_ picker views - those that the user has not provided an initial value for.
    fileprivate let emptyPickersStack = UIStackView.newAutoLayout()

    // MARK: - Picker Views

    /// The picker view for setting the user's step goal.
    fileprivate let stepGoalPicker = PreferencesActivityPickerView.newAutoLayout()
    
    /// The picker view for setting the user's mindfulneww goal.
    fileprivate let mindfulnessGoalPicker = PreferencesActivityPickerView.newAutoLayout()

    /// The picker view for setting the user's weight.
    fileprivate let weightPicker = PreferencesActivityPickerView.newAutoLayout()

    /// The picker view for setting the user's height.
    fileprivate let heightPicker = PreferencesActivityPickerView.newAutoLayout()

    // MARK: - Birthday Views

    /// The view for setting the user's birthday.
    fileprivate let birthdayView = PreferencesBirthdayView.newAutoLayout()

    // MARK: - HealthKit Views

    /// The view for linking with HealthKit, or displaying the linked state.
    fileprivate let healthKitView = PreferencesActivityHealthKitView.newAutoLayout()

    // MARK: - Units
    fileprivate let units = Locale.current.preferredUnits

    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view

        // stack view layout settings
        [rootStack, filledPickersStack, emptyPickersStack].forEach({ stack in
            stack.alignment = .fill
            stack.axis = .vertical
        })

        // space elements of stack views
        [rootStack, filledPickersStack].forEach({ $0.spacing = 45 })
        emptyPickersStack.spacing = 24

        // add the root stack view - which is inset on the vertical axis from the root view
        view.addSubview(rootStack)
        rootStack.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets(top: 43, left: 0, bottom: 58, right: 0))

        // step goal picker is always visible in the filled stack, since it cannot be skipped or nil
        filledPickersStack.addArrangedSubview(stepGoalPicker)
        filledPickersStack.addArrangedSubview(mindfulnessGoalPicker)

        // add a title label for this section to the root stack view
        let title = UILabel.newAutoLayout()
        title.textColor = .white
        title.attributedText = UIFont.gothamBook(15).track(250, "ACTIVITY SETTINGS").attributedString
        title.textAlignment = .center
        rootStack.addArrangedSubview(title)

        // add HealthKit view to root stack - this view will always be visible, although it changes its contents
        rootStack.addArrangedSubview(healthKitView)

        // add header label to empty stack
        emptyPickersStack.addArrangedSubview(PreferencesActivityViewController.emptyStackLabelView())

        // picker titles
        stepGoalPicker.title = "DAILY STEPS GOAL"
        mindfulnessGoalPicker.title = "MINDFUL MINUTES GOAL"
        weightPicker.title = "WEIGHT"
        heightPicker.title = "HEIGHT"
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let goalFormatter = NumberFormatter()
        goalFormatter.usesGroupingSeparator = true
        goalFormatter.numberStyle = .decimal

        
        let selectBodyMassController:((Services) -> SelectBodyMassViewController) = { SelectBodyMassViewController(services: $0) }
        let selectHeightController:((Services) -> SelectHeightViewController) = { SelectHeightViewController(services: $0) }

        // allow user to adjust steps goal
        let preferences = services.preferences
        
        stepGoalPicker.actionsProducer.startWithValues({ action in
            let offset = 500 * (action == .increase ? 1 : -1)
            
            preferences.activityTrackingStepsGoal.pureModify({ current in
                min(20000, max(500, current + offset))
            })
        })
        
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
        
        stepGoalPicker.quantityComponents <~ services.preferences.activityTrackingStepsGoal.producer.map({ steps in
            [UnitStringComponent(string: stepsFormatter.string(from: NSNumber(value: steps)) ?? String(steps), part: .value)]
        })
        
        mindfulnessGoalPicker.quantityComponents <~ services.preferences.activityTrackingMindfulnessGoal.producer.map({ minutes in
            [UnitStringComponent(string: stepsFormatter.string(from: NSNumber(value: minutes)) ?? String(minutes), part: .value)]
        })


        // allow the user to adjust body measurements
        enable(
            picker: weightPicker,
            property: services.preferences.activityTrackingBodyMass,
            unit: units.bodyMass,
            offset: 1,
            formatter: units.bodyMassFormatter,
            makeController: selectBodyMassController
        )

        enable(
            picker: heightPicker,
            property: services.preferences.activityTrackingHeight,
            unit: units.height,
            offset: 1,
            formatter: units.heightFormatter,
            makeController: selectHeightController
        )

        // bind state of birthday view and use it to enter birthday
        birthdayView.birthday <~ services.preferences.activityTrackingBirthDateComponents.producer.map({ $0?.value })

        birthdayView.editTappedProducer.startWithValues({ [weak self] in
            guard let strong = self else { return }

            let controller = SelectBirthDateViewController()
            controller.initialDateComponents =
                strong.services.preferences.activityTrackingBirthDateComponents.value?.value

            strong.present(
                controller: controller,
                producer: controller.selectedDateComponentsProducer,
                property: strong.services.preferences.activityTrackingBirthDateComponents
            )
        })

        // bind state of HealthKit view and use it to enable HealthKit
        healthKitView.connected <~ services.activityTracking.healthKitAuthorization.producer
            .equals(.sharingAuthorized)
            .observe(on: UIScheduler())

        startRequestingHealthKitAccess(on: healthKitView.connectTappedProducer)

        // modify stack views as values are filled
        let stackViewParametersProducer: SignalProducer<(Bool, Bool, Bool), NoError> = SignalProducer.combineLatest(
            heightPicker.quantityComponents.producer.map({ $0 != nil }),
            weightPicker.quantityComponents.producer.map({ $0 != nil }),
            birthdayView.birthday.producer.map({ $0 != nil })
        )

        stackViewParametersProducer
            .skipRepeats(==)
            .startWithValues({ [weak self] heightFilled, weightFilled, birthdayFilled in
                self?.updateStackViews(
                    heightFilled,
                    weightFilled: weightFilled,
                    birthdayFilled: birthdayFilled
                )
            })
    }
}

extension PreferencesActivityViewController
{
    // MARK: - Updating Layout

    /// Updates the view controller's stack views, moving filled and unfilled picker views to the correct stack.
    ///
    /// - parameter heightFilled:   Whether or not the height picker is filled.
    /// - parameter weightFilled:   Whether or not the weight picker is filled.
    /// - parameter birthdayFilled: Whether or not the birthday picker is filled.
    fileprivate func updateStackViews(_ heightFilled: Bool, weightFilled: Bool, birthdayFilled: Bool)
    {
        let children: [(view: UIView, filled: Bool)] = [
            (view: heightPicker, filled: heightFilled),
            (view: weightPicker, filled: weightFilled),
            (view: birthdayView, filled: birthdayFilled)
        ]

        for (view, filled) in children
        {
            view.removeFromSuperview()
            (filled ? filledPickersStack : emptyPickersStack).addArrangedSubview(view)
        }

        // remove stacks without views - the empty stack has a fixed title label view
        for (stack, count) in [(filledPickersStack, 0), (emptyPickersStack, 1)]
        {
            if stack.arrangedSubviews.count == count
            {
                stack.removeFromSuperview()
            }
            else if stack.superview == nil
            {
                // HealthKit is always the last item in the root stack
                rootStack.insertArrangedSubview(stack, at: rootStack.arrangedSubviews.count - 1)
            }
        }
    }

    static func emptyStackLabelView() -> UIView
    {
        let view = UIView.newAutoLayout()

        let label = UILabel.newAutoLayout()
        label.attributedText = "Add your details to track Calories & Distance".preferencesBodyAttributedString
        label.numberOfLines = 0
        label.textColor = .white
        view.addSubview(label)

        label.autoFloatInSuperview(alignedTo: .vertical)
        label.autoPinEdgeToSuperview(edge: .top, inset: 6)
        label.autoPinEdgeToSuperview(edge: .bottom)
        label.autoSet(dimension: .width, to: 200)

        return view
    }
}

extension PreferencesActivityViewController
{
    // MARK: - Binding and Adding Body Data

    /// Binds and enables a body data picker.
    ///
    /// - parameter picker:         The picker to bind and enable.
    /// - parameter property:       The property to bind to and edit.
    /// - parameter unit:           The unit to use with the property.
    /// - parameter formatter:      A formatting function for converting the property's quantity to a string.
    /// - parameter makeController: A function to create a confirmable data view controller of the appropriate type.
    fileprivate func enable<ConfirmableViewController: UIViewController>(
                            picker: PreferencesActivityPickerView,
                            property: MutableProperty<Skippable<PreferencesHKQuantity>?>,
                            unit: HKUnit,
                            offset: Double,
                            formatter: @escaping PreferredUnits.Formatter,
                            makeController: @escaping (Services) -> ConfirmableViewController
                            ) where ConfirmableViewController: Confirmable
    {
        picker.quantityComponents <~ property.producer.formatted(formatter)

        picker.actionsProducer.startModifying(property: property, unit: unit, offset: offset)

        picker.addProducer.startWithValues({ [weak self] _ in
            guard let strong = self else { return }

            let controller = makeController(strong.services)

            strong.present(
                controller: controller,
                producer: SignalProducer(controller.confirmedValueSignal),
                property: property
            )
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

extension SignalProducerProtocol where Value == Skippable<PreferencesHKQuantity>?
{
    func formatted(_ formatter: @escaping PreferredUnits.Formatter) -> SignalProducer<[UnitStringComponent]?, Error>
    {
        return mapOptionalFlat({ skippable in
            (skippable.value?.quantity).map(formatter)
        })
    }
}

extension SignalProducerProtocol where Value == PreferencesActivityPickerView.Action, Error == NoError
{
    // MARK: - Modifying Properties

    /**
     Starts modifying `property`, based on actions sent by the receiver.

     - parameter property: The property to modify.
     - parameter unit:     The unit to use when modifying the value of `property`.
     - parameter offset:   The amount of offset to use when modifying the value of `property`.
     */
    @discardableResult
    fileprivate func startModifying<Property: ModifiableMutablePropertyType>
        (property: Property, unit: HKUnit, offset: Double) -> Disposable where Property.Value == Skippable<PreferencesHKQuantity>?
    {
        return startWithValues({ action in
            let signedOffset: Double = offset * (action == .increase ? 1 : -1)

            property.pureModify({ optionalCurrent in
                optionalCurrent.map({ current in
                    current.map({ value in
                        let modified = round(value.quantity.doubleValue(for: unit) + signedOffset)
                        return modified > 0 ? PreferencesHKQuantity(unit: unit, doubleValue: modified) : value
                    })
                })
            })
        })
    }
}
