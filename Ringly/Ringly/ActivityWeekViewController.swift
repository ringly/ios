import HealthKit
import PureLayout
import ReactiveSwift
import Result
import RinglyActivityTracking
import RinglyExtensions
import UIKit


final class ActivityWeekViewController: ServicesViewController
{
    // MARK: - Initialization
    override init(services: Services)
    {
        bottomViewController = ActivityWeekBottomViewController(services: services)
        goalsViewController = ActivityGoalsViewController(services: services, statisticsController: statisticsController)
        super.init(services: services)
    }
    
    // MARK: - State
    
    /// `true` when the view controller's view has appeared.
    fileprivate let viewHasAppeared = MutableProperty(false)
    
    // MARK: - Signals

    /// Yields a boundary dates value when the user taps a selected day.
    let (tappedSelectedBoundaryDatesSignal, tappedSelectedBoundaryDatesObserver) = Signal<BoundaryDates, NoError>.pipe()
    
    /// Yields a boundary dates value when the user taps mindfulness summary
    let (tappedMindfulnessDatesSignal, tappedMindfulnessDatesObserver) = Signal<BoundaryDates, NoError>.pipe()

    // MARK: - Current Week
    
    /// The current day range to display.
    let calendarBoundaryDatesResult = MutableProperty(Result<CalendarBoundaryDates?, NSError>?.none)

    fileprivate let scrollView = UIScrollView.newAutoLayout()
    
    /// The current week data controller.
    fileprivate let dataController = MutableProperty(BoundaryDatesDataController?.none)
    
    fileprivate let mindfulController = MutableProperty(MindfulDatesDataController?.none)
    
    // MARK: - Bottom Content
    
    /// The bottom controller, containing the graph or empty interface.
    fileprivate let bottomViewController: ActivityWeekBottomViewController
    
    fileprivate let goalsViewController: ActivityGoalsViewController
    
    // MARK: - Selected Values
    
    /// The currently selected boundary dates.
    fileprivate let selectedBoundaryDates = MutableProperty(BoundaryDates?.none)
    
    /// The statistics controller, which will calculate values for the selected date.
    let statisticsController = ActivityStatisticsController(
        distanceUnit: Locale.current.preferredUnits.distance
    )
    
    // MARK: - Subviews
    
    /// The controls/progress interface displayed by this view.
    fileprivate let statisticsView = ActivityStatisticsView.newAutoLayout()
    
    
    fileprivate let pullState = MutableProperty<PullState>(.none)
    
    fileprivate let secondsToNewSync = MutableProperty(Int?.none)
    
    fileprivate var errorCount:Int?
    
    // MARK: - View Loading
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        // set up the scroll view
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()
        
        // add stack view for preferences
        let container = UIView.newAutoLayout()
        scrollView.addSubview(container)
        
        container.autoPinEdgeToSuperview(edge: .top)
        container.autoPin(edge: .left, to: .left, of: self.view)
        container.autoPin(edge: .right, to: .right, of: self.view)
        container.autoPinEdgeToSuperview(edge: .bottom, inset: 0)
        container.autoMatch(dimension: .height, to: .height, of: self.view, offset: 1)
        container.autoAlignAxis(toSuperviewAxis: .vertical)
        container.autoAlignAxis(toSuperviewAxis: .horizontal)

        // add controls
        statisticsView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statisticsView)
        
        // add bottom view controller
        addChildViewController(bottomViewController)
        container.addSubview(bottomViewController.view)
        bottomViewController.view.autoPin(edge: .top, to: .bottom, of: statisticsView, offset: 0)
        bottomViewController.view.autoPinEdgeToSuperview(edge: .left, inset: 0)
        bottomViewController.view.autoPinEdgeToSuperview(edge: .right, inset: 0)
        bottomViewController.didMove(toParentViewController: self)

        // upper content layout
        statisticsView.autoPinEdgeToSuperview(edge: .top)
        statisticsView.autoPinEdgeToSuperview(edge: .left, inset: 0)
        statisticsView.autoPinEdgeToSuperview(edge: .right, inset: 0)

        
        addChildViewController(goalsViewController)
        container.addSubview(goalsViewController.view)
        goalsViewController.view.autoPin(edge: .top, to: .bottom, of: bottomViewController.view, offset: 3)
        goalsViewController.view.autoPinEdgeToSuperview(edge: .left, inset: 0)
        goalsViewController.view.autoPinEdgeToSuperview(edge: .right, inset: 0)
        goalsViewController.view.autoPinEdgeToSuperview(edge: .bottom, inset: 0)
        goalsViewController.didMove(toParentViewController: self)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let services = self.services
        let scheduler = UIScheduler()
        
        let cache = ActivityCache(
            fileURL: FileManager.default.rly_cachesURL
                .appendingPathComponent("activity-week.realm")
        )
        
        // create a week data controller for the current week
        let viewHasAppearedProducer = viewHasAppeared.producer
        
        dataController <~ calendarBoundaryDatesResult.producer.map({ $0?.value.flatten() }).mapOptional({
            let controller = BoundaryDatesDataController(
                dataSource: services.activityTracking,
                cache: cache,
                boundaryDates: $0.dayBoundaryDates
            )
            
            controller.queriesEnabled <~ viewHasAppearedProducer
            
            return controller
        })
        
        mindfulController <~ calendarBoundaryDatesResult.producer.map({ $0?.value.flatten() }).mapOptional({
            let controller = MindfulDatesDataController(
                dataSource: services.activityTracking,
                cache: cache,
                boundaryDates: $0.dayBoundaryDates
            )
            
            return controller
        })
        
        selectedBoundaryDates <~ dataController.producer.mapOptional({ $0.boundaryDates })
            .combineLatest(with: bottomViewController.selectedColumnIndexProducer)
            .map(unwrap)
            .mapOptionalFlat({ $0[safe: $1] })
            .map({ optionalBoundaryDates in
                return optionalBoundaryDates ?? BoundaryDates.today()
            })

        
        // bind the current week data to the graph
        let stepsGoalProducer = services.preferences.activityTrackingStepsGoal.producer
        let mindfulMinutesGoalProducer = services.preferences.activityTrackingMindfulnessGoal

        let graphDataProducer:SignalProducer<GraphData?, NoError> = dataController.producer
            .graphDataProducer(stepsGoalProducer: stepsGoalProducer)
            .observe(on: scheduler)
        
        bottomViewController.graphData <~ graphDataProducer
        
        bottomViewController.graphColumnOffset <~ calendarBoundaryDatesResult.producer.map({ optionalBoundaryDates in
            optionalBoundaryDates?.value.flatten().flatMap({ dates -> Int? in
                (dates.calendar.range(of: .weekday, in: .weekOfYear, for: dates.boundaryDates.start)?.count).map({
                    dates.calendar.component(.weekday, from: dates.boundaryDates.start) - $0 - 1
                })
            }) ?? 0
        })

        // notify when requesting navigation to a day
        let dayTappedProducer = SignalProducer.merge([
            bottomViewController.tappedSelectedColumnProducer,
            SignalProducer(statisticsView.steps.reactive.controlEvents(.touchUpInside)).void,
            SignalProducer(self.goalsViewController.stepGoalSummaryView.reactive.controlEvents(.touchUpInside)).void
            ]
        )
        
        let mindfulnessTappedProducer = SignalProducer(self.goalsViewController.mindfulnessGoalSummaryView.reactive.controlEvents(.touchUpInside)).void
        
        goalsViewController.showSteps <~ graphDataProducer.map({ $0 != nil ? true : false })
        
        selectedBoundaryDates.producer.sample(on: mindfulnessTappedProducer)
            .skipNil()
            .start(tappedMindfulnessDatesObserver)

        selectedBoundaryDates.producer.sample(on: dayTappedProducer)
            .skipNil()
            .start(tappedSelectedBoundaryDatesObserver)
        
        // track the currently highlighted steps data
        statisticsController.steps <~ dataController.producer
            .flatMapOptional(.latest, transform: { $0.steps.producer })
            .combineLatest(with: bottomViewController.selectedColumnIndexProducer)
            .map(unwrap)
            .mapOptionalFlat({ results, column in results[safe: column]??.value })
        
        statisticsController.mindfulMinutes <~ mindfulController.producer
            .flatMapOptional(.latest, transform: { $0.mindfulMinute.producer })
            .combineLatest(with: bottomViewController.selectedColumnIndexProducer)
            .map(unwrap)
            .mapOptionalFlat({ results, column in results[safe: column]??.value })

        statisticsController.stepsGoal <~ stepsGoalProducer
        statisticsController.mindfulnessGoal <~ mindfulMinutesGoalProducer
        
        statisticsController.bodyMass <~ services.preferences.activityTrackingBodyMass.producer.map({ $0?.value?.quantity })
        statisticsController.height <~ services.preferences.activityTrackingHeight.producer.map({ $0?.value?.quantity })

        statisticsController.dayProgress <~ selectedBoundaryDates.producer.combineLatest(with: viewHasAppearedProducer)
            .map(unwrap)
            .flatMapOptional(.latest, transform: { dates, hasAppeared -> SignalProducer<Double, NoError> in
                hasAppeared
                    ? dates.progressProducer(updating: .seconds(10), on: QueueScheduler.main)
                    : SignalProducer.empty
            })
            .map({ $0 ?? 0 })
            .skipRepeats()
        
        statisticsController.age <~ services.preferences.activityTrackingBirthDateComponents.producer
            .map({ $0?.value })
            .combineLatest(with: calendarBoundaryDatesResult.producer.map({ result in
                // workaround for nil result causing calories to always appear unfulfilled
                result?.value??.calendar ?? Calendar.current
            }))
            .map(unwrap)
            .mapOptionalFlat({ components, calendar in
                calendar.date(from: components).flatMap({ birth in
                    // using the current date and not updating is close enough for measuring in years
                    (calendar.dateComponents([.year], from: birth, to: Date()).year).map({ year in
                        max(0, year)
                    })
                })
            })
        
        // bind statistics view to controller
        statisticsView.bind(to: statisticsController)
        
        // start displaying bottom content, now that graph data is populated
        bottomViewController.displayContents.value = true
        
        // present detail alerts when the user taps a calculation
        requestedStatisticsCalculationDetailsProducer.startWithValues({ [weak self] calculation in
            guard let strong = self else { return }
            
            strong.presentAlert { alert in
                alert.actionGroup = .close
                
                switch calculation
                {
                case .calories:
                    alert.content = AlertImageTextContent(
                        image: UIImage(asset: .activityTrackingCaloriesIcon),
                        text: trUpper(.calories),
                        detailText: tr(.caloriesExplanation)
                    )
                    
                case .distance:
                    alert.reactive.content <~ strong.services.activityTracking.healthKitAuthorization.producer
                        .map({ (status: HKAuthorizationStatus) -> AlertViewControllerContent? in
                            AlertImageTextContent(
                                image: UIImage(asset: .activityTrackingDistanceIcon),
                                text: trUpper(.distance),
                                detailText: tr(status == HKAuthorizationStatus.sharingAuthorized
                                    ? .distanceExplanationWithHealth
                                    : .distanceExplanationWithoutHealth
                                )
                            )
                        })
                }
            }
        })
        
        
        // fade activity indicator in and out
        services.peripherals.readingActivityTrackingData.producer
            .skipRepeats()
            .observe(on: UIScheduler())
            .take(until: reactive.lifetime.ended)
            .startWithValues({ show in 
                if show {
                    self.pullState.value = .loading
                } else {
                    guard self.pullState.value != .none else {
                        return
                    }
                    
                    self.pullState.value = .finished
                    
                    RLYDispatchAfterMain(0.75, {
                        self.pullState.value = .none
                    })
                }
        })
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        viewHasAppeared.value = true
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        viewHasAppeared.value = false
    }
}

extension ActivityWeekViewController
{
    private var requestedStatisticsCalculationProducer: SignalProducer<(ActivityStatisticsCalculation, Bool), NoError>
    {
        let views = [
            (statisticsView.distance, ActivityStatisticsCalculation.distance),
            (statisticsView.calories, ActivityStatisticsCalculation.calories)
        ]
        
        return SignalProducer.merge(views.map({ control, calculation in
            control.showValueText.producer.sample(
                on: SignalProducer(control.reactive.controlEvents(.touchUpInside)).void
                ).map({ (calculation, $0) })
        }))
    }
    
    var requestedStatisticsCalculationDetailsProducer: SignalProducer<ActivityStatisticsCalculation, NoError>
    {
        return requestedStatisticsCalculationProducer.filter({ $1 == true }).map({ calculation, _ in calculation })
    }
    
    var requestedStatisticsCalculationOnboardingProducer: SignalProducer<ActivityStatisticsCalculation, NoError>
    {
        return requestedStatisticsCalculationProducer.filter({ $1 == false }).map({ calculation, _ in calculation })
    }
}

extension ActivityWeekViewController: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let lastSyncDate = self.services.preferences.activityEventLastReadCompletionDate.value {
            self.secondsToNewSync.value = Int(lastSyncDate.addingTimeInterval(61).timeIntervalSince1970.subtracting(Date().timeIntervalSince1970))
        } else {
            self.secondsToNewSync.value = nil
        }
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y <= 0 else {
            self.scrollView.setContentOffset(CGPoint.zero, animated: false)
            return
        }
        
        let offset = Float(scrollView.contentOffset.y)
        let releasePoint:Float = 70
        
        if self.pullState.value == .countingError && offset == 0 {
            self.pullState.value = .none
            return
        }
        
        guard ![.loading, .finished, .error, .countingError].contains(self.pullState.value) else {
            return
        }
        
        let lastSyncDate = self.services.preferences.activityEventLastReadCompletionDate.value
        
        let progress = min(-offset / Float(releasePoint), 1.0)
        
        switch offset {
        case 0:
            self.pullState.value = .none
        case -releasePoint ... 0:
            self.pullState.value = .pulling(pullProgress: Double(progress), lastSync:lastSyncDate)
        case -1000 ... -releasePoint:
            if !scrollView.isDragging {
                if let activatedPeripheral = self.services.peripherals.activatedPeripheral.value, activatedPeripheral.isConnected {
                    if let lastSyncDate = lastSyncDate, (Date().timeIntervalSince1970 - lastSyncDate.timeIntervalSince1970) < 60 {
                        if let errorCount = self.errorCount {
                            if errorCount >= 2 {
                                self.pullState.value = .error
                                self.presentRefreshedTooSoonAlert()
                            } else {
                                self.pullState.value = .countingError
                                self.errorCount! += 1
                            }
                        } else {
                            self.pullState.value = .countingError
                            self.errorCount = 1
                        }
                    } else {
                        self.errorCount = nil
                        
                        if activatedPeripheral.isValidated {
                            self.pullState.value = .loading
                            self.services.activityTracking.syncObserver.send(value: .pullToRefresh)
                        } else {
                            self.pullState.value = .none
                        }
                    }

                } else {
                    self.pullState.value = .error
                    self.presentNotConnectedAlert()
                }
            } else {
                self.pullState.value = .releaseToLoad(pullProgress: Double(progress), lastSync:lastSyncDate)
            }
        default:
            break
        }
    }

    var titleProducer: SignalProducer<NavigationBar.Title?, NoError> {
        return self.pullState.producer.flatMap(.latest, transform: { pullState -> SignalProducer<NavigationBar.Title?, NoError> in
            switch pullState {
            case .countingError:
                return SignalProducer.empty
            case .error:
                return SignalProducer.empty
            case .none:
                return self.selectedDateStringProducer.map({ NavigationBar.Title.text($0!) })
            case .pulling(let pullProgress, let lastSync):
                let lastSyncDate = lastSync ?? Date()
                let lastSyncString = "Steps Updated \(Date().dayRelativeString(since: lastSync ?? Date()))"

                if let secondsToNewSync = self.secondsToNewSync.value, lastSyncDate.addingTimeInterval(60).isWithin60Seconds(date: Date()) {
                    return self.selectedDateStringProducer.map({ NavigationBar.Title.textWithSubtitle(text: $0!, subtitle: "\(lastSyncString)\nNew steps in \(secondsToNewSync) sec", pullProgress: pullProgress) })
                } else {
                    let title = NavigationBar.Title.textWithSubtitle(text:"PULL TO SYNC", subtitle: lastSyncString, pullProgress: pullProgress)
                    return SignalProducer(value: title)
                }
            case .releaseToLoad(let pullProgress, let lastSync):
                let lastSyncDate = lastSync ?? Date()
                let lastSyncString = "Steps Updated \(Date().dayRelativeString(since: lastSync ?? Date()))"

                if let secondsToNewSync = self.secondsToNewSync.value, lastSyncDate.addingTimeInterval(60).isWithin60Seconds(date: Date()) {
                    return self.selectedDateStringProducer.map({ NavigationBar.Title.textWithSubtitle(text: $0!, subtitle: "\(lastSyncString)\nNew steps in \(secondsToNewSync) sec", pullProgress: pullProgress) })
                } else {
                    let title =  NavigationBar.Title.textWithSubtitle(text: "RELEASE TO SYNC", subtitle: lastSyncString, pullProgress: pullProgress)
                    return SignalProducer(value: title)
                }
            case .loading:
                let diamondActivity = DiamondActivityIndicator.newAutoLayout()
                diamondActivity.autoSetDimensions(to: CGSize.init(width: 18, height: 18))
                let title =  NavigationBar.Title.textWithIcon(text: "SYNCING...", view: diamondActivity)
                return SignalProducer(value: title)
            case .finished:
                let imageView = UIImageView.newAutoLayout()
                imageView.autoSetDimensions(to: CGSize.init(width: 18, height: 18))
                imageView.image = Asset.syncedCheckmark.image
                imageView.contentMode = .scaleAspectFit
                let title = NavigationBar.Title.textWithIcon(text: "SYNCED", view: imageView)
                return SignalProducer(value: title)
            }
        })
    }
    
    var selectedDateStringProducer: SignalProducer<String?, NoError>
    {
        // date formatters for the current and past years
        let differentYearFormatter = DateFormatter(localizedFormatTemplate: "EMMMdYYYY")
        let sameYearFormatter = DateFormatter(localizedFormatTemplate: "EMMMMd")
        
        // a producer of the current calendar the controller is using
        let calendarProducer = calendarBoundaryDatesResult.producer.mapOptionalFlat({ $0.value??.calendar })
        
        // a producer of the current calendar and a date representative of "today" within it
        let calendarDateProducer = calendarProducer.flatMapOptional(.latest, transform: { calendar in
            calendar.immediateDailyTimer(on: QueueScheduler.main)
                .map({ (calendar, $0) })
        })
        
        return calendarDateProducer.combineLatest(with: selectedBoundaryDates.producer)
            .map(unwrap)
            .mapOptional(append)
            .skipRepeatsOptional(==)
            .mapOptional({ calendar, current, boundaryDates -> String in
                // special handling for the current day
                guard !boundaryDates.contains(date: current) else { return trUpper(.today) }
                
                // for dates in the current year, do not include the year in the resulting string
                let currentYear = calendar.component(.year, from: Date())
                let formatter = currentYear == calendar.component(.year, from: boundaryDates.start)
                    ? sameYearFormatter
                    : differentYearFormatter
                
                // format the date to a string and add style attributes
                return formatter.string(from: boundaryDates.start).uppercased()
            })
            .map({ $0 ?? trUpper(.activity) })
    }
    
    func presentNotConnectedAlert() {
        presentAlert { alert in
            alert.content = AlertImageTextContent(text: "RINGLY NOT FOUND!", detailText: "We noticed you’re trying to refresh your data but aren’t connected to a Ringly.")
            
            alert.actionGroup = .double(
                action: (title: tr(.connect), dismiss: true, action: {
                    self.pullState.value = .none
                    
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.switchTab(tab: .connection)
                    }
                }),
                dismiss:(title: tr(.notNow), dismiss: true, action: {
                    self.pullState.value = .none
                })
            )
        }
    }
    
    func presentRefreshedTooSoonAlert() {
        presentAlert { alert in
            alert.content = AlertImageTextContent(text: "YOUR STEPS WILL BE READY SOON", detailText: "Just a heads up, step data is available from your Ringly once per minute. Take a quick breather then refresh.")
            
            alert.actionGroup = .single(action: (title: tr(.gotIt), dismiss: true, action: {
                self.pullState.value = .none
            }))
        }
    }
}

extension ActivityWeekViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        bottomViewController.tabBarViewControllerDidTapSelectedItem()
    }
}

// MARK: - Graph Data
extension SignalProducerProtocol where Value == BoundaryDatesDataController?, Error == NoError
{
    fileprivate func graphDataProducer(stepsGoalProducer: SignalProducer<Int, NoError>)
        -> SignalProducer<GraphData?, NoError>
    {
        let formatter = DateFormatter(localizedFormatTemplate: "Md")
        let combined = SignalProducer.combineLatest(producer, stepsGoalProducer).map(unwrap)
        
        return combined.flatMapOptional(.latest, transform: { controller, goal -> SignalProducer<GraphData, Error> in
            controller.graphDataProducer(stepsGoal: goal, columnDateFormatter: formatter)
        })
    }
}

extension BoundaryDatesDataController
{
    fileprivate func graphDataProducer(stepsGoal: Int, columnDateFormatter: DateFormatter)
        -> SignalProducer<GraphData, NoError>
    {
        return steps.producer.map({ $0.stepsValues }).map({ columns -> GraphData in
            GraphData(
                columns: columns.map({ CGFloat($0.stepCount) }),
                maximumValue: CGFloat(stepsGoal) * 1.5,
                goal: stepsGoal,
                labelForColumn: { column in
                    (self.boundaryDates[safe: column]?.start).map(columnDateFormatter.string)
            }
            )
        })
    }
}


extension Date {
    func isWithin60Seconds(date: Date) -> Bool {
        let timeDiff = self.timeIntervalSince1970 - date.timeIntervalSince1970
        return timeDiff >= 0 && timeDiff <= 60
    }
    
    func secondsFromNow() -> TimeInterval
    {
        return self.timeIntervalSince1970 - Date().timeIntervalSince1970
    }
}
