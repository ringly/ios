import HealthKit
import PureLayout
import ReactiveSwift
import Result
import RinglyExtensions
import UIKit

protocol Confirmable {
    var confirmedValueSignal: Signal<PreferencesHKQuantity, NoError> { get }
}


class SelectBodyDataViewController: ServicesViewController, Confirmable
{
    // MARK: - Signals

    /// A backing pipe for `confirmedValueSignal`.
    fileprivate let confirmedValuePipe = Signal<PreferencesHKQuantity, NoError>.pipe()

    /// A signal that sends the selected value when the user taps the confirmation button.
    var confirmedValueSignal: Signal<PreferencesHKQuantity, NoError>
    {
        return confirmedValuePipe.0
    }

    // MARK: - Configuration
    fileprivate let configuration = MutableProperty(SelectBodyDataConfiguration?.none)

    // MARK: - View Loading

    /// A label displaying an instruction to the user.
    fileprivate let promptLabel = UILabel.newAutoLayout()

    /// A label displaying the currently selected value.
    fileprivate let valueLabel = UILabel.newAutoLayout()

    /// The button that the user taps to confirm a selected value.
    fileprivate let confirmButton = ButtonControl.newAutoLayout()

    /// The view controller displaying the selection interface.
    fileprivate let ticksViewController = TicksViewController()

    /// The view controller displaying the highlighted version of the selection interface.
    fileprivate let highlightTicksViewController = TicksViewController()

    /// The mask view for `highlightTicksViewController`.
    fileprivate let highlightTicksMask = UIView.newAutoLayout()

    fileprivate let highlightContainer = HighlightedTickContainerView.newAutoLayout()

    override func loadView()
    {
        let view = UIView()
        self.view = view

        // label setup
        promptLabel.numberOfLines = 0
        promptLabel.textColor = .white
        view.addSubview(promptLabel)

        valueLabel.textColor = .white
        view.addSubview(valueLabel)

        // button setup
        confirmButton.title = trUpper(.next)
        view.addSubview(confirmButton)

        // upper content layout
        let height = DeviceScreenHeight.current

        promptLabel.autoPinEdgeToSuperview(edge: .top, inset: height.select(four: 10, preferred: 53))
        promptLabel.autoFloatInSuperview(alignedTo: .vertical)

        valueLabel.autoPin(edge: .top, to: .bottom, of: promptLabel, offset: height.select(four: 10, five: 20, preferred: 68))
        valueLabel.autoFloatInSuperview(alignedTo: .vertical)

        confirmButton.autoPin(edge: .top, to: .bottom, of: valueLabel, offset: height.select(four: 10, five: 20, preferred: 45))
        confirmButton.autoAlignAxis(toSuperviewAxis: .vertical)
        confirmButton.autoSetDimensions(to: CGSize(width: 155, height: 50))

        // add ticks view controller
        addChildViewController(ticksViewController)
        view.addSubview(ticksViewController.view)
        ticksViewController.view.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.zero, excluding: .top)
        ticksViewController.view.autoSet(dimension: .height, to: 110)
        ticksViewController.didMove(toParentViewController: self)

        // add highlight container view
        highlightContainer.isUserInteractionEnabled = false
        view.addSubview(highlightContainer)

        highlightContainer.autoPinEdgeToSuperview(edge: .bottom)
        highlightContainer.autoAlignAxis(toSuperviewAxis: .vertical)
        highlightContainer.autoSetDimensions(to: CGSize(width: 10, height: 85))

        // add highlighted ticks
        highlightTicksMask.backgroundColor = UIColor.black
        highlightTicksViewController.view.mask = highlightTicksMask

        highlightTicksViewController.tickColor.value = UIColor(red: 0.8033, green: 0.5397, blue: 0.7062, alpha: 1.0)
        highlightTicksViewController.view.isUserInteractionEnabled = false

        addChildViewController(highlightTicksViewController)
        view.addSubview(highlightTicksViewController.view)

        [ALEdge.left, .right, .top, .bottom].forEach({ edge in
            highlightTicksViewController.view.autoPin(edge: edge, to: edge, of: ticksViewController.view)
        })

        highlightTicksViewController.didMove(toParentViewController: self)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // match scrolling of ticks view controllers
        ticksViewController.didScroll = { [weak self] offset, _ in
            self?.highlightTicksViewController.scroll(to: offset, animated: false)
        }

        // update the ticks view controllers when configuration changes
        configuration.producer.startWithValues({ [weak self] configuration in
            // update appearance
            self?.ticksViewController.ticksAppearance = (configuration?.pattern).map({ pattern in
                TicksAppearance(
                    heightFraction: 1,
                    tickWidth: 2.5,
                    tickSpacing: 15.5,
                    alpha: (major: 1, minor: 0.3),
                    pattern: pattern
                )
            })

            self?.highlightTicksViewController.ticksAppearance = (configuration?.pattern).map({ pattern in
                TicksAppearance(
                    heightFraction: 1,
                    tickWidth: 2.5,
                    tickSpacing: 15.5,
                    alpha: (major: 1, minor: 1),
                    pattern: pattern
                )
            })

            // update data
            self?.ticksViewController.ticksData = configuration.map({ configuration in
                LazyTitleTicksData(
                    tickCount: configuration.stepCount,
                    titleFunction: { index in
                        let value = configuration.startValue + configuration.stepSize * index
                        return configuration.tickTitleString(value)
                    }
                )
            })

            self?.highlightTicksViewController.ticksData = configuration.map({ configuration in
                LazyTitleTicksData(
                    tickCount: configuration.stepCount,
                    titleFunction: { _ in "" }
                )
            })
        })

        // bind the text of the value label
        SignalProducer.combineLatest(ticksViewController.selectedTickProducer, configuration.producer)
            .map({ tick, maybeConfiguration in
                maybeConfiguration.map({ configuration -> AttributedStringProtocol in
                    let value = configuration.startValue + configuration.stepSize * tick
                    return configuration.valueString(value)
                })
            })
            .startWithValues({ [weak valueLabel] maybeText in valueLabel?.attributedText = maybeText?.attributedString })

        // send confirmation events to signal observers
        SignalProducer.combineLatest(ticksViewController.selectedTickProducer, configuration.producer)
            .sample(on: SignalProducer(confirmButton.reactive.controlEvents(.touchUpInside)).void)
            .map({ tick, maybeConfiguration in
                maybeConfiguration.map({ configuration in
                    PreferencesHKQuantity(
                        unit: configuration.displayUnit,
                        doubleValue: Double(configuration.startValue + configuration.stepSize * tick)
                    )
                })
            })
            .skipNil()
            .start(confirmedValuePipe.1)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)

        if let configuration = self.configuration.value
        {
            // async to work around layout glitch, look at more later
            DispatchQueue.main.async(execute: {
                let tick = configuration.defaultValue - configuration.startValue
                self.ticksViewController.select(tick: tick, animated: false)
            })
        }
    }

    // MARK: - Layout
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()

        // update the frame of the highlight ticks mask
        highlightTicksMask.frame = highlightTicksViewController.view
            .convert(highlightContainer.bounds, from: highlightContainer)
    }
}

private struct SelectBodyDataConfiguration
{
    /// The display unit to use.
    let displayUnit: HKUnit

    /// The starting value.
    let startValue: Int

    /// The size of each step, represented by a tick.
    let stepSize: Int

    /// The number of steps, represented by a tick.
    let stepCount: Int

    /// The value that the picker should start on.
    let defaultValue: Int

    /// The tick pattern.
    let pattern: [CGFloat]

    /// A function to determine the tick title strings.
    let tickTitleString: (Int) -> String

    /// A function to determine the value strings.
    let valueString: (Int) -> AttributedStringProtocol
}

extension SelectBodyDataConfiguration
{
    // MARK: - Height Configurations

    /// A configuration for selecting the user's height in the Imperial system.
    static func feetAndInches(_ current: HKQuantity?) -> SelectBodyDataConfiguration
    {
        return SelectBodyDataConfiguration(
            displayUnit: HKUnit.inch(),
            startValue: 36,
            stepSize: 1,
            stepCount: 61,
            defaultValue: 66,
            pattern: [
                heights.full,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial
            ],
            tickTitleString: { inches in
                "\(inches / 12) \(trUpper(.feetShort))"
            },
            valueString: { inches in
                let bigFont = UIFont.gothamBook(54)
                let smallFont = UIFont.gothamBook(22.5)

                return [
                    String(inches / 12).attributes(font: bigFont),
                    "\(trUpper(.feetShort))     ".attributes(font: smallFont),
                    String(inches % 12).attributes(font: bigFont),
                    trUpper(.inchesShort).attributes(font: smallFont)
                ].join()
            }
        )
    }

    // MARK: - Body Mass Configurations

    /// A configuration for selecting the user's body mass in the Imperial system.
    static func pounds(_ current: HKQuantity?) -> SelectBodyDataConfiguration
    {
        return SelectBodyDataConfiguration(
            displayUnit: HKUnit.pound(),
            startValue: 75,
            stepSize: 1,
            stepCount: 226,
            defaultValue: 120,
            pattern: [
                heights.full,
                heights.partial,
                heights.partial,
                heights.partial,
                heights.partial
            ],
            tickTitleString: String.init,
            valueString: { pounds in
                return [
                    String(pounds).attributes(font: .gothamBook(54)),
                    trUpper(.poundsShort).attributes(font: .gothamBook(22.5))
                ].join()
            }
        )
    }
}

// MARK: - Select Height View Controller
final class SelectHeightViewController: SelectBodyDataViewController
{
    override func loadView()
    {
        super.loadView()

        promptLabel.attributedText = [
            tr(.activityHeightPromptLine1),
            tr(.activityHeightPromptLine2)
        ].promptAttributedString

        configuration.value = SelectBodyDataConfiguration.feetAndInches(
            services.preferences.activityTrackingHeight.value?.value?.quantity
        )
    }
}

// MARK: - Select Body Mass View Controller
final class SelectBodyMassViewController: SelectBodyDataViewController
{
    override func loadView()
    {
        super.loadView()

        promptLabel.attributedText = [
            tr(.activityWeightPromptLine1),
            tr(.activityWeightPromptLine2)
        ].promptAttributedString

        configuration.value = SelectBodyDataConfiguration.pounds(
            services.preferences.activityTrackingBodyMass.value?.value?.quantity
        )
    }
}

// MARK: - SequenceType Title Extensions
extension Sequence where Iterator.Element == String
{
    fileprivate var promptAttributedString: NSAttributedString
    {
        let font = UIFont.gothamBook(18)
        let style = NSParagraphStyle.with(alignment: .center, lineSpacing: 8)

        let styled = map({ string in
            font.track(250, string).attributes(paragraphStyle: style)
        })

        let withNewlines = styled.dropLast().flatMap({ string in [string, "\n"].join() }) + styled.suffix(1)
        return (withNewlines as [AttributedStringProtocol]).join().attributedString
    }
}


/// The heights used for ticks.
private let heights = (full: CGFloat(0.75), partial: CGFloat(0.55))


// MARK: - Supporting Views
private final class HighlightedTickContainerView: UIView
{
    // MARK: - Initialization
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - Drawing
    fileprivate override func draw(_ rect: CGRect)
    {
        let size = bounds.size
        let inset: CGFloat = 2

        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: inset, width: size.width, height: size.height - inset))
        UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: inset * 2)).fill()
    }
}
