import ReactiveSwift
import RinglyExtensions
import UIKit

private let barHeightMultipliers: [CGFloat] = [
    0.09177,
    0.206500956,
    0.4933078394,
    0.4187380497,
    0.8432122371
]

final class OnboardingGraphView: UIView
{
    // MARK: - Subviews
    fileprivate let bars = BarsView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add shadow at bottom of view
        let shadow = OnboardingShadowView.newAutoLayout()
        addSubview(shadow)

        shadow.autoPinEdgeToSuperview(edge: .bottom)
        shadow.autoFloatInSuperview(alignedTo: .vertical)
        shadow.autoMatch(dimension: .width, to: .height, of: shadow, multiplier: 21.85)

        // add container for bars content, above shadow
        addSubview(bars)
        bars.autoPinEdgeToSuperview(edge: .top)
        bars.autoAlignAxis(toSuperviewAxis: .vertical)
        bars.autoMatch(dimension: .width, to: .width, of: shadow, multiplier: 0.919)
        bars.autoMatch(dimension: .width, to: .height, of: bars, multiplier: 0.978)
        bars.autoConstrain(attribute: .bottom, to: .horizontal, of: shadow)
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

    // MARK: - Animation
    func playAnimation()
    {
        bars.playAnimation()
    }
}

private final class BarsView: UIView
{
    // MARK: - Subviews

    /// The bars that make up the graph.
    fileprivate let bars = (0..<5).map({ _ -> UIView in
        let view = UIView.newAutoLayout()
        view.backgroundColor = .white
        return view
    })

    /// The dots placed on top of each bar.
    fileprivate let dots = (0..<5).map({ _ -> UIView in
        let dot = UIView.newAutoLayout()
        dot.alpha = 0
        dot.backgroundColor = UIColor(red: 1.0, green: 0.5039, blue: 0.4858, alpha: 1.0)
        dot.layer.borderColor = UIColor.white.cgColor
        return dot
    })

    /// The lines between each pair of dots.
    fileprivate let lines = (0..<4).map({ _ -> LineView in
        let line = LineView.newAutoLayout()
        line.alpha = 0
        return line
    })

    fileprivate let flagPole = UIView.newAutoLayout()
    fileprivate let flag = FlagView.newAutoLayout()

    // MARK: - Layout
    fileprivate var barCollapsedConstraints: [NSLayoutConstraint] = []
    fileprivate var barExpandedConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add bars to container
        bars.dropLast().forEach({ $0.alpha = 0.7 })
        bars.last?.alpha = 0.9

        bars.forEach({ bar in
            addSubview(bar)
            bar.autoPinEdgeToSuperview(edge: .bottom)
        })

        // adjust bar height depending on animation state
        barCollapsedConstraints = bars.map({ $0.autoSet(dimension: .height, to: 0) })
        barExpandedConstraints = zip(bars, barHeightMultipliers).map({ bar, multiplier in
            bar.autoMatch(dimension: .height, to: .height, of: self, multiplier: multiplier)
        })
        barExpandedConstraints.forEach({ $0.isActive = false })

        // arrange bars horizontally
        let barPairs = zip(bars.dropLast(), bars.dropFirst())

        let spacers = (0..<(bars.count - 1)).map({ _ in UIView.newAutoLayout() })
        spacers.forEach(addSubview)

        zip(spacers, barPairs).forEach({ spacer, bars in
            spacer.autoPin(edge: .left, to: .right, of: bars.0)
            spacer.autoPin(edge: .right, to: .left, of: bars.1)
        })

        (bars as NSArray).autoMatchViews(dimension: .width)
        (spacers as NSArray).autoMatchViews(dimension: .width)

        bars.first?.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.1797)
        bars.first?.autoPinEdgeToSuperview(edge: .left)
        bars.last?.autoPinEdgeToSuperview(edge: .right)

        // determine line directions
        let lineDirections = zip(barHeightMultipliers.dropLast(), barHeightMultipliers.dropFirst())
            .map({ $0 > $1 ? LineViewDirection.descending : .ascending })

        zip(lines, lineDirections).forEach({ $0.direction = $1 })

        // add lines to view
        lines.forEach(addSubview)

        zip(zip(lines, bars.dropLast()), bars.dropFirst()).map(append).forEach({ line, leftBar, rightBar in
            // center the ends of the line on the bars
            line.autoConstrain(attribute: .left, to: .vertical, of: leftBar)
            line.autoConstrain(attribute: .right, to: .vertical, of: rightBar)

            // when the bars are flat, these constraints might break - the lines aren't visible then anyways
            NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultLow, forConstraints: {
                if line.direction == .ascending
                {
                    line.autoPin(edge: .bottom, to: .top, of: leftBar)
                    line.autoPin(edge: .top, to: .top, of: rightBar)
                }
                else
                {
                    line.autoPin(edge: .top, to: .top, of: leftBar)
                    line.autoPin(edge: .bottom, to: .top, of: rightBar)
                }
            })
        })

        // add flagpole
        flagPole.alpha = 0
        flagPole.backgroundColor = .white
        addSubview(flagPole)

        bars.last?.autoAlign(axis: .vertical, toSameAxisOf: flagPole)
        bars.last?.autoPin(edge: .top, to: .bottom, of: flagPole)
        bars.last?.autoMatch(dimension: .width, to: .width, of: flagPole, multiplier: 1 / BarsView.lineWidthFactor)
        flagPole.autoMatch(dimension: .height, to: .height, of: self, multiplier: 1 - barHeightMultipliers[4])

        // add flag with spacer
        flag.alpha = 0
        addSubview(flag)

        flag.autoMatch(dimension: .height, to: .height, of: flagPole, multiplier: 0.7032967033)
        flag.autoMatch(dimension: .width, to: .height, of: flag, multiplier: 0.8421052632)
        flag.autoConstrain(attribute: .top, to: .bottom, of: flagPole, multiplier: 0.02197802198)

        let flagSpacer = UIView.newAutoLayout()
        addSubview(flagSpacer)

        flagSpacer.autoPin(edge: .left, to: .right, of: flag)
        flagSpacer.autoPin(edge: .right, to: .left, of: flagPole)
        flagSpacer.autoMatch(dimension: .width, to: .width, of: flagPole, multiplier: 2.25)

        // place dots on the top of bars
        dots.forEach({ dot in
            addSubview(dot)
            dot.autoMatch(dimension: .width, to: .height, of: dot)
        })

        zip(dots, bars).forEach({ dot, bar in
            dot.autoAlign(axis: .vertical, toSameAxisOf: bar)
            dot.autoConstrain(attribute: .horizontal, to: .top, of: bar)
            dot.autoMatch(dimension: .width, to: .width, of: bar, multiplier: 0.333)
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
    fileprivate static let lineWidthFactor: CGFloat = 0.04297

    fileprivate override func layoutSubviews()
    {
        super.layoutSubviews()

        let barWidth = bars[0].bounds.size.width
        let lineWidth = barWidth * BarsView.lineWidthFactor
        let dotCornerRadius = dots[0].bounds.size.width / 2

        dots.forEach({ dot in
            dot.layer.borderWidth = lineWidth
            dot.layer.cornerRadius = dotCornerRadius
        })

        lines.forEach({ line in
            line.lineWidth = lineWidth
        })

        flagPole.layer.cornerRadius = flagPole.bounds.size.width / 2
    }

    // MARK: - Animation
    fileprivate func playAnimation()
    {
        let animationProducers = zip(barExpandedConstraints, barCollapsedConstraints).enumerated()
            .map({ index, constraints in
                UIView.animationProducer(duration: 0.5, delay: Double(index) * 0.1, animations: {
                    constraints.1.isActive = false
                    constraints.0.isActive = true
                    self.layoutIfInWindowAndNeeded()
                })
            })

        let dotProducers = dots.enumerated().map({ index, dot in
            UIView.animationProducer(duration: 0.25, delay: Double(index) * 0.1, animations: {
                dot.alpha = 1
            })
        })

        let lineProducers = lines.enumerated().map({ index, line in
            UIView.animationProducer(duration: 0.25, delay: Double(index) * 0.1, animations: {
                line.alpha = 1
            })
        })

        let flagProducer = UIView.animationProducer(duration: 0.25, animations: {
            self.flag.alpha = 1
            self.flagPole.alpha = 1
        })

        SignalProducer.merge(animationProducers)
            .then(SignalProducer.merge(dotProducers))
            .then(SignalProducer.merge(lineProducers))
            .then(flagProducer)
            .start()
    }
}

/// Draws the flag for `OnboardingGraphView`.
private final class FlagView: UIView
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
        let bounds = self.bounds

        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.minX, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.close()

        UIColor(red: 0.9685, green: 0.8298, blue: 0.554, alpha: 1.0).setFill()
        path.fill()
    }
}
