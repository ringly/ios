import ReactiveSwift
import UIKit
import enum Result.NoError

final class ActivityWeekBottomViewController: ServicesViewController
{
    // MARK: - Graph Data

    /// When `false`, this view controller will not display any contents.
    let displayContents = MutableProperty(false)

    ///
    let graphData = MutableProperty(GraphData?.none)
    let graphColumnOffset = MutableProperty(0)

    // MARK: - View Loading
    fileprivate let container = ContainerViewController()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        container.childTransitioningDelegate = self
        container.addAsEdgePinnedChild(of: self, in: view)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // update the container view controller whenever the graph data changes
        
        SignalProducer.combineLatest(
                graphData.producer,
                displayContents.producer,
                self.services.peripherals.references.producer
            )
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] in
                let hasTrackingDevice = $2.filter({ reference in  reference.activityTrackingSupport == .supported }).count > 0
                self?.updateContainer($0, displayContents: $1, hasTrackingDevice: hasTrackingDevice)
            })
    }

    // MARK: - Updating View
    fileprivate func updateContainer(_ optionalGraphData: GraphData?, displayContents: Bool, hasTrackingDevice: Bool)
    {
        if displayContents
        {
            if let graphData = optionalGraphData
            {
                self.loadGraph(graphData: graphData)
            }
            else
            {
                if hasTrackingDevice {
                    let stepsGoal = services.preferences.activityTrackingStepsGoal
                    self.loadGraph(graphData: GraphData.empty(goal: stepsGoal.value))
                } else {
                    container.updateServicesChild(type: ActivityEmptyViewController.self, services: services)
                }
            }
        }
        else
        {
            container.childViewController.value = nil
        }
    }
    
    fileprivate func loadGraph(graphData: GraphData?) {
        container.updateChild(
            type: GraphViewController.self,
            make: {
                let controller = GraphViewController()
                controller.columnOffset <~ graphColumnOffset
                return controller
        },
            update: { (controller: GraphViewController) in
                controller.data.value = graphData
        }
        )
    }
}

extension ActivityWeekBottomViewController
{
    // MARK: - Graph Producers

    /// A producer for the current graph view controller.
    fileprivate var graphViewControllerProducer: SignalProducer<GraphViewController?, NoError>
    {
        return container.childViewController.producer.map({ $0 as? GraphViewController })
    }

    /// If a graph is being displayed, a producer for the selected column index. Otherwise, sends `nil`.
    var selectedColumnIndexProducer: SignalProducer<Int?, NoError>
    {
        return graphViewControllerProducer.flatMapOptional(.latest, transform: { $0.selectedColumnIndexProducer })
    }

    /// Sends a value when the user taps the selected graph column.
    var tappedSelectedColumnProducer: SignalProducer<(), NoError>
    {
        return graphViewControllerProducer
            .flatMapOptional(.latest, transform: { SignalProducer($0.tappedSelectedColumnSignal).void })
            .skipNil()
    }
}

extension ActivityWeekBottomViewController: TabBarViewControllerTappedSelectedListener
{
    func tabBarViewControllerDidTapSelectedItem()
    {
        (container.childViewController.value as? GraphViewController)?.scrollToLastColumn(animated: true)
    }
}

extension ActivityWeekBottomViewController: ContainerViewControllerTransitioningDelegate
{
    func containerViewController(containerViewController: ContainerViewController,
                                 animationControllerForTransitionFromViewController fromViewController: UIViewController?,
                                 toViewController: UIViewController?)
        -> UIViewControllerAnimatedTransitioning?
    {
        if fromViewController is GraphViewController && toViewController != nil
        {
            return DayToWeekTransitionController(operation: .pop)
        }
        else if toViewController is GraphViewController && fromViewController != nil
        {
            return DayToWeekTransitionController(operation: .push)
        }
        else if fromViewController != nil && toViewController != nil
        {
            return CrossDissolveTransitionController(duration: 0.25)
        }
        else
        {
            return nil
        }
    }
}
