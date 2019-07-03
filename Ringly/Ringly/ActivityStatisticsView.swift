import Foundation
import ReactiveSwift
import RinglyExtensions

final class ActivityStatisticsView: UIView
{
    // MARK: - Controls
    let steps = ActivityProgressControl.init(strokeWidth: 9.5, withShadow: true)
    let calories = ActivityCircleControl.newAutoLayout()
    let distance = ActivityCircleControl.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(distance)
        addSubview(calories)
        
        [distance, calories].forEach({ $0.autoSetDimensions(to: ActivityCircleControl.size) })

        // add steps last, so that it is on top
        steps.title.value = (
            text: trUpper(.steps),
            icon: UIImage(asset: .activityTrackingStepsIcon)
        )

        addSubview(steps)

        steps.autoAlignAxis(toSuperviewAxis: .vertical)
        steps.autoPinEdgeToSuperview(edge: .top)
        steps.autoPinEdgeToSuperview(edge: .bottom, inset: 0)
        
        let stepsWidth:CGFloat = DeviceScreenHeight.current.select(four: 95.0, five: 95.0, six: 137.0, sixPlus: 137.0, preferred: 137.0)
        steps.autoSetDimensions(to: CGSize(width: stepsWidth, height: stepsWidth))
        
        calories.autoPin(edge: .bottom, to: .bottom, of: steps)
        distance.autoPin(edge: .bottom, to: .bottom, of: steps)
        calories.autoPin(edge: .left, to: .right, of: steps, offset: -14)
        distance.autoPin(edge: .right, to: .left, of: steps, offset:  14)
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

    // MARK: - Binding

    /// Binds the view's data-displaying subviews to a statistics controller's properties.
    ///
    /// - Parameter statisticsController: The statistics controller to bind to.
    @discardableResult
    @nonobjc func bind(to statisticsController: ActivityStatisticsController) -> Disposable
    {
        let scheduler = UIScheduler()

        return CompositeDisposable([
            steps.data <~ statisticsController.stepsControlData.producer.observe(on: scheduler),
            distance.valueText <~ statisticsController.distanceValueText.producer.observe(on: scheduler),
            distance.valueType <~ statisticsController.distanceValueType.producer.observe(on: scheduler),
            distance.showValueText <~ statisticsController.haveDistancePrerequisites.producer.observe(on: scheduler),
            calories.valueText <~ statisticsController.caloriesValueText.producer.observe(on: scheduler),
            calories.valueType <~ statisticsController.caloriesValueType.producer.observe(on: scheduler),
            calories.showValueText <~ statisticsController.haveKilocaloriePrerequisites.producer.observe(on: scheduler)
        ])
    }
}
