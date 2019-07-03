import ReactiveSwift
import RinglyActivityTracking
import RinglyExtensions
import UIKit
import enum Result.NoError

final class ActivityDayViewController: ServicesViewController
{
    // MARK: - Configuration Properties

    /// The calendar used by this view controller.
    let calendar = MutableProperty(Calendar?.none)

    /// The boundary dates for the day displayed by this view controller.
    let dayBoundaryDates = MutableProperty(BoundaryDates?.none)

    // MARK: - Statistics Value Texts

    /// The number of steps to display in the statistics cell.
    let stepsProgressText = MutableProperty(ActivityControlData?.none)
    
    /// The current number of steps taken so far.
    let stepsCount = MutableProperty<Int>(0)
    
    /// The most active hour.
    let activeHourString = MutableProperty<String>("")
    let activeHourInt = MutableProperty<Int>(0)
    
    /// The most active hour's steps.
    let activeHourSteps = MutableProperty<Int>(0)
    
    /// The wake up hour.
    let wakeupHourString = MutableProperty<String>("")
    let wakeupHourInt = MutableProperty<Int>(0)
    
    /// Wakeup detected
    let wakeupDetected = MutableProperty<Bool>(false)
    
    // MARK: - Bound Properties

    /// The hourly boundary dates, derived from `calendar` and `dayBoundaryDates`.
    fileprivate let hourBoundaryDates = MutableProperty([BoundaryDates]?.none)

    /// A data controller that will load steps data for `hourBoundaryDates`.
    fileprivate let hoursDataController = MutableProperty(BoundaryDatesDataController?.none)

    /// The current hourly steps data result, if any.
    fileprivate let hoursStepsData = MutableProperty<[Steps]?>(nil)
    
    fileprivate let firstActivityTime = MutableProperty<Date?>(Date())

    /// The current translation offset, which is used to offset the tab bar.
    let currentTranslationOffset = MutableProperty<Bool>(false)
    
    // MARK: - Subviews

    /// A back button, to dismiss the view.
    fileprivate let backButton = UIButton.newAutoLayout()

    /// The collection view displaying the view controller's interface.
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ActivityDayCollectionViewLayout())
    
    // MARK: - Table View
    
    fileprivate let tableView = UITableView.newAutoLayout()

    // MARK: - View Loading
    override func loadView()
    {
        super.loadView()
        
        let container = UIView.newAutoLayout()
        view.addSubview(container)
        container.autoPinEdgesToSuperviewEdges()
        container.autoMatch(dimension: .height, to: .height, of: self.view, offset: 1)
        
        // collection view setup
        collectionView.backgroundColor = .clear
        container.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges()
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let cache = ActivityCache(
            fileURL: FileManager.default.rly_cachesURL
                .appendingPathComponent("activity-day.realm")
        )
    

        // enable collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.clipsToBounds = false

        // register cell classes
        collectionView.registerCellType(ActivityDayGraphCell.self)
        collectionView.registerCellType(ActivityDayProgressCell.self)
        collectionView.registerCellType(ActivityDayHighlightsCell.self)
        collectionView.registerCellType(ActivityDayEmptyStateCell.self)
        collectionView.registerCellType(ActivityIndicatorCollectionViewCell.self)

        // determine the hourly boundary dates of the current boundary dates
        hourBoundaryDates <~ calendar.producer.combineLatest(with: dayBoundaryDates.producer)
            .map(unwrap)
            .mapOptional({ $0.boundaryDatesForHours(from: $1.start, to: $1.end) })

        // create an data controller for the current hourly boundary dates
        let activityTracking = services.activityTracking

        hoursDataController <~ hourBoundaryDates.producer
            .mapOptionalFlat({ boundaryDates in
                let controller = BoundaryDatesDataController(
                    dataSource: activityTracking,
                    cache: cache,
                    boundaryDates: boundaryDates
                )

                controller.queriesEnabled.value = true
                return controller
            })

        // store the result from the hourly data controller
        hoursStepsData <~ hoursDataController.producer
            .flatMapOptional(.latest, transform: { $0.steps.producer })
            .mapOptionalFlat({ results in results.map({ $0?.value }).unwrapped })
            .skipRepeatsOptional(==)
        
        // only take the first steps after 5AM
        func updatedDate(dateStart: Date) -> Date {
            let fiveHours = DateComponents(calendar: Calendar.current, hour: 5)
            let startComponents = Calendar.current.date(byAdding: fiveHours, to: dateStart)
            return startComponents ?? dateStart
        }
        
        firstActivityTime <~ dayBoundaryDates.producer.skipNil().flatMap(.latest, transform: { dates in
            return self.services.activityTracking.stepsBoundaryDateProducer(ascending: true, startDate: updatedDate(dateStart: dates.start), endDate: dates.end)
        }).mapErrorToValue({ _ in
            return nil
        })

        // reload collection view when entering and exiting loading state
        hoursStepsData.producer
            .map({ $0 != nil })
            .skipRepeats()
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] _ in
                if self?.collectionView.window != nil
                {
                    let set = NSMutableIndexSet()
                    set.add(ActivityDayCollectionViewLayout.Section.loading.rawValue)
                    set.add(ActivityDayCollectionViewLayout.Section.graph.rawValue)
                    self?.collectionView.reloadSections(set as IndexSet)
                }
            })

        // pop when back button is tapped
        SignalProducer(backButton.reactive.controlEvents(.touchUpInside)).startWithValues({ [weak self] _ in
            _ = self?.navigationController?.popViewController(animated: true)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentTranslationOffset.value = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentTranslationOffset.value = false
    }
}

extension ActivityDayViewController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        switch ActivityDayCollectionViewLayout.Section(rawValue: section)!
        {
        case .loading:
            return hoursStepsData.value == nil ? 1 : 0
        case .graph:
            return hoursStepsData.value != nil ? 1 : 0
        case .progress:
            return 1
        case .highlights:
            return stepsCount.value != 0 ? 1 : 0
        case .emptyState:
            return stepsCount.value == 0 ? 1 : 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        switch ActivityDayCollectionViewLayout.Section(rawValue: indexPath.section)!
        {
        case .loading:
            return collectionView.dequeueCellOfType(ActivityIndicatorCollectionViewCell.self, forIndexPath: indexPath)

        case .graph:
            let cell = collectionView.dequeueCellOfType(ActivityDayGraphCell.self, forIndexPath: indexPath)

            hoursStepsData.producer
                .mapOptional({ data in data.map({ $0.stepCount }) })
                .observe(on: UIScheduler())
                .take(until: SignalProducer(cell.reactive.prepareForReuse))
                .startWithValues({ [weak cell] data in
                    guard let cell = cell else { return }
                    cell.data.value = data
                    
                    // only have hourly view when there is steps data
                    guard let maximum = data?.max() else { return }
                    let barsShown = maximum != 0
                    cell.enableToolTip(bool: barsShown)
                    
                    // color current hour white and place dot
                    let startDay = Calendar.current.dateComponents([.year, .month, .day], from: (self.hourBoundaryDates.value?.first?.start)!)
                    if startDay == Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    {
                        cell.barsView.colorCurrentHour(hour: Calendar.current.dateComponents([.hour], from: Date()).hour!)
                    }
                    
                    if let strongData = data, maximum != 0 {
                        self.activeHourSteps.value = maximum
                        if let index = strongData.index(of: maximum) {
                            self.activeHourString.value = convertToStandardTime(hour: index)
                            self.activeHourInt.value = index
                        }
                    }
                    
                    if cell.window != nil
                    {
                        UIView.animate(withDuration: 0.25, animations: { cell.layoutIfNeeded() })
                    }
                })
            
            self.firstActivityTime.producer.startWithValues({ date in
                if let date = date {
                    let dateFormatter = DateFormatter(localizedFormatTemplate: "h:mma")
                    self.wakeupHourString.value = dateFormatter.string(from: date).uppercased()
                    self.wakeupHourInt.value = Calendar.current.dateComponents([.hour], from: date).hour!
                    self.wakeupDetected.value = true
                } else {
                    self.wakeupDetected.value = false
                }
            })

            // place icons on appropriate hours
            cell.barsView.topHour <~ activeHourInt
            cell.barsView.wakeupHour <~ wakeupHourInt
            
            SignalProducer.combineLatest(
                cell.barsView.topHour.producer,
                cell.barsView.wakeupHour.producer
                )
                .startWithValues({ (topHour, wakeupHour) in
                    cell.barsView.starViews.forEach({ $0.alpha = 0.0 })
                    cell.barsView.sunViews.forEach({ $0.alpha = 0.0 })
                    
                    cell.barsView.starViews[topHour].alpha = 1.0
                    if wakeupHour != 0 && wakeupHour != topHour {
                        cell.barsView.sunViews[wakeupHour].alpha = 1.0
                    }
                })
            
            return cell
            
        case .progress:
            let cell = collectionView.dequeueCellOfType(ActivityDayProgressCell.self, forIndexPath: indexPath)
            let stepsGoalProducer = services.preferences.activityTrackingStepsGoal.producer
            cell.moveMoreView.count <~ stepsCount
            cell.moveMoreView.activityControlData <~ stepsProgressText
            cell.moveMoreView.goal <~ stepsGoalProducer.observe(on: UIScheduler())
        
            return cell
            
        case .highlights:
            let cell = collectionView.dequeueCellOfType(ActivityDayHighlightsCell.self, forIndexPath: indexPath)
            
            // add wakeup view if necessary
            self.wakeupDetected.producer.first().map({ _ in
                self.updateHighlightCells(cell: cell)
            })
            
            // bind hour and step count to highlight cells
            cell.wakeupModel.time <~ wakeupHourString
            cell.topHourModel.time <~ activeHourString
            cell.topHourModel.count! <~ activeHourSteps
            
            return cell
        
        case .emptyState:
            let cell = collectionView.dequeueCellOfType(ActivityDayEmptyStateCell.self, forIndexPath: indexPath)
         
            return cell
        }
    }
    
    // update highlight models to include wakeup cell if wakeup detected
    func updateHighlightCells(cell: ActivityDayHighlightsCell)
    {
        if cell.highlightModels.count < 2 {
            cell.highlightModels.insert(cell.wakeupModel, at: 0)
            cell.tableView.reloadData()
        }
    }
}

func convertToStandardTime(hour: Int) -> String
{
    if hour == 0 { return "12AM - 1AM" }
    else if hour < 11 { return "\(hour)AM - \(hour+1)AM" }
    else if hour == 11 { return "11AM - 12PM" }
    else if hour == 12 { return "12PM - 1PM" }
    else if hour == 23 { return "11PM - 12AM" }
    else { return "\(hour-12)PM - \(hour-11)PM" }
}

