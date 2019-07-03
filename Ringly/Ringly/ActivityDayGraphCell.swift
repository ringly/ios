import PureLayout
import ReactiveSwift
import RinglyExtensions
import UIKit

final class ActivityDayGraphCell: UICollectionViewCell
{
    // MARK: - Data
    let data = MutableProperty([Int]?.none)
    let barsView = ActivityDayGraphBarsView.newAutoLayout()
    let draggingGesture = UIPanGestureRecognizer()
    let lineContainer = ActivityDayLineView.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        // add bars view
        contentView.addSubview(barsView)
        barsView.autoPinEdgeToSuperview(edge: .top, inset: 10)
        barsView.autoPinEdgeToSuperview(edge: .left, inset: 20)
        barsView.autoPinEdgeToSuperview(edge: .right, inset: 20)
        
        contentView.addSubview(lineContainer)
        lineContainer.autoPinEdgeToSuperview(edge: .top, inset: 10)
        lineContainer.autoPinEdgeToSuperview(edge: .left, inset: 20)
        lineContainer.autoPinEdgeToSuperview(edge: .right, inset: 20)
        
        // add bottom images
        let bottomContainer = UIView.newAutoLayout()
        contentView.addSubview(bottomContainer)

        bottomContainer.autoPin(edge: .top, to: .bottom, of: barsView)
        bottomContainer.autoPin(edge: .top, to: .bottom, of: lineContainer)
        bottomContainer.autoPinEdgesToSuperviewEdges(excluding: .top)
        bottomContainer.autoSet(dimension: .height, to: 30)

        [ALEdge.left, .right].forEach({ edge in
            let midnight = UILabel.newAutoLayout()
            midnight.textColor = .white
            midnight.attributedText = UIFont.gothamBook(12).track(30, "12").attributedString
            bottomContainer.addSubview(midnight)
            midnight.autoAlignAxis(toSuperviewAxis: .horizontal)
            midnight.autoPinEdgeToSuperview(edge: edge, inset: 20)
            
            if edge == .right
            {
                let sixAm = UILabel.newAutoLayout()
                sixAm.textColor = .white
                sixAm.attributedText = UIFont.gothamBook(12).track(30, "6").attributedString
                bottomContainer.addSubview(sixAm)
                sixAm.autoAlignAxis(toSuperviewAxis: .horizontal)
                
                let sixPm = UILabel.newAutoLayout()
                sixPm.textColor = .white
                sixPm.attributedText = UIFont.gothamBook(12).track(30, "6").attributedString
                bottomContainer.addSubview(sixPm)
                sixPm.autoAlignAxis(toSuperviewAxis: .horizontal)
            
                let noon = UILabel.newAutoLayout()
                noon.textColor = .white
                noon.attributedText = UIFont.gothamBook(12).track(30, "noon").attributedString
                bottomContainer.addSubview(noon)
                noon.autoAlignAxis(toSuperviewAxis: .horizontal)
                
                sixAm.autoConstrain(attribute: .leading, to: .trailing, of: midnight, multiplier: 0.297)
                noon.autoConstrain(attribute: .leading, to: .trailing, of: midnight, multiplier: 0.502)
                sixPm.autoConstrain(attribute: .leading, to: .trailing, of: midnight, multiplier: 0.7741)
            }
        })

        // bind bars view data
        data.signal.observeValues({ self.barsView.data = $0 })
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

    func enableToolTip(bool: Bool)
    {
        if bool {
            barsView.addGestureRecognizer(draggingGesture)
            draggingGesture.minimumNumberOfTouches = 1
            draggingGesture.addTarget(self, action: #selector(self.giveHourlyUpdates(_:)))
            lineContainer.isHidden = true
        }
        else{
            barsView.isHidden = true
        }
    }
    
    func giveHourlyUpdates(_ pan: UIPanGestureRecognizer)
    {
        switch pan.state
        {
        case .ended:
            UIView.animate(withDuration: 0.1, animations: {
                self.barsView.barShadowViews.forEach({ view in
                    view.isHidden = true})
                self.barsView.stepLabelViews.forEach({ view in
                    view.isHidden = true})
            })
        default:
            let barWidth = (barsView.frame.width - 2.0 * CGFloat(24 - 1)) / CGFloat(24)
            let point = pan.location(in: barsView)
            // bar view location
            let selectedBar = (point.x/(barWidth + 2)).rounded(.down)
            // needs to fall within day hours
            if selectedBar >= 0 && selectedBar <= 23.0
            {
                UIView.animate(withDuration: 0.2, animations: {
                    self.barsView.barShadowViews.enumerated().forEach({ index, view in
                        view.isHidden = true
                        self.barsView.stepLabelViews[index].isHidden = true
                    })
                })
                barsView.currentHourSteps(hour: Int(selectedBar))
            }
        }
    }
    
    // MARK: - Layout
    @nonobjc fileprivate static let lineThickness: CGFloat = 1
    @nonobjc fileprivate static let baseLineThickness: CGFloat = 2
}

final class ActivityDayLineView: UIView
{
    fileprivate var lineViews: [UIView] =  []
    fileprivate var labelViews: [ActivityDayGraphLabelView] = []
    fileprivate let barCount = 24
    
    override func layoutSubviews()
    {
        super.layoutSubviews()

        lineViews.match(barCount, makeElement: { _ in
            let barView = UIView()
            barView.backgroundColor = UIColor(red: 230/255.0, green: 197/255.0, blue: 214/255.0, alpha: 1.0)
            addSubview(barView)
            return barView
        })
        
        let maximum = 1000
        var labelPrecision = 100
        
        while maximum / labelPrecision > 5
        {
            labelPrecision += 100
        }
        
        labelViews.match(maximum / labelPrecision, makeElement: { index in
            let labelView = ActivityDayGraphLabelView()
            labelView.alpha = 0.4
            insertSubview(labelView, at: 0)
            return labelView
        })
        
        labelViews.enumerated().forEach({ index, view in
            view.number = (index + 1) * labelPrecision
        })
        
        let size = bounds.size
        let padding: CGFloat = 2
        let barWidth = (size.width - padding * CGFloat(barCount - 1)) / CGFloat(barCount)
        
        lineViews.enumerated().forEach({ index, view in
            let barHeight = 2
            
            view.frame = CGRect(
                x: (barWidth + padding) * CGFloat(index),
                y: size.height - CGFloat(barHeight),
                width: barWidth,
                height: CGFloat(barHeight)
            )
            
        })
        
        let pointsPerValue = size.height / CGFloat(maximum)
        
        labelViews.forEach({ view in
            let viewSize = view.systemLayoutSizeFitting(CGSize.max)
            let yOffset = round(pointsPerValue * CGFloat(view.number))
            
            view.frame = CGRect(
                x: 0,
                y: size.height - yOffset - viewSize.height,
                width: size.width,
                height: viewSize.height
            )
        })
    }
}

final class ActivityDayGraphBarsView: UIView
{
    // MARK: - Data
    var data: [Int]?
    {
        didSet
        {
            let barCount = data?.count ?? 0
            
            barShadowViews.match(barCount, makeElement: { _ in
                let barView = UIView()
                barView.backgroundColor = UIColor(red: 162/255.0, green: 93/255.0, blue: 140/255.0, alpha: 0.5)
                addSubview(barView)
                barView.isHidden = true
                return barView
            })
            
            barViews.match(barCount, makeElement: { _ in
                let barView = UIView()
                barView.backgroundColor = UIColor(red: 230/255.0, green: 197/255.0, blue: 214/255.0, alpha: 1.0)
                addSubview(barView)
                return barView
            })
            
            stepLabelViews.match(barCount, makeElement: { hour in
                let tooltip = ActivityDayHourLabelView(hour: hour)
                addSubview(tooltip)
                tooltip.isHidden = true
                return tooltip
            })

            dotViews.match(barCount, makeElement: { _ in
                let dotView = UIView()
                dotView.backgroundColor = .clear
                addSubview(dotView)
                return dotView
            })
            
            dots.match(barCount, makeElement: { _ in
                let dot = UIView()
                dot.autoSetDimensions(to: CGSize(width: 4.0, height: 4.0))
                dot.backgroundColor = .clear
                dot.layer.cornerRadius = 2.0
                dot.clipsToBounds = true
                return dot
            })
            
            starViews.match(barCount, makeElement: { _ in
                let starView = UIImageView(image: Asset.starSmall.image)
                starView.contentMode = .scaleAspectFit
                starView.alpha = 0.0
                addSubview(starView)
                return starView
            })
            
            sunViews.match(barCount, makeElement: { _ in
                let sunView = UIImageView(image: Asset.sunSmall.image)
                sunView.contentMode = .scaleAspectFit
                sunView.alpha = 0.0
                addSubview(sunView)
                return sunView
            })
            
            let maximum = data?.max() ?? 0
            var labelPrecision = 100

            while maximum / labelPrecision > 5
            {
                labelPrecision += 100
            }

            labelViews.match(maximum / labelPrecision, makeElement: { index in
                let labelView = ActivityDayGraphLabelView()
                labelView.alpha = 0.4
                insertSubview(labelView, at: 0)
                return labelView
            })

            labelViews.enumerated().forEach({ index, view in
                view.number = (index + 1) * labelPrecision
            })

            setNeedsLayout()
        }
    }

    // MARK: - Subviews
    fileprivate var barViews: [UIView] = []
    fileprivate var barShadowViews: [UIView] = []
    fileprivate var labelViews: [ActivityDayGraphLabelView] = []
    fileprivate var dotViews: [UIView] = []
    fileprivate var dots: [UIView] = []
    fileprivate var stepLabelViews: [ActivityDayHourLabelView] = []
    var starViews: [UIImageView] = []
    var sunViews: [UIImageView] = []
    
    // MARK: - Properties
    let topHour = MutableProperty<Int>(0)
    let wakeupHour = MutableProperty<Int>(0)
    
    // MARK: - Layout
    override func layoutSubviews()
    {
        super.layoutSubviews()

        guard let data = self.data, let maximum = data.max(), maximum > 0 else { return }

        let size = bounds.size
        let padding: CGFloat = 2
        let barWidth = (size.width - padding * CGFloat(data.count - 1)) / CGFloat(data.count)
        
        zip(data, barViews).enumerated().map(prepend).forEach({ index, data, view in
            let barHeight = max( size.height * (CGFloat(data) / CGFloat(maximum)), 2)

            view.frame = CGRect(
                x: (barWidth + padding) * CGFloat(index),
                y: size.height - barHeight,
                width: barWidth,
                height: barHeight
            )
            
        })
        
        zip(data, barShadowViews).enumerated().map(prepend).forEach({ index, data, view in
            let barHeight = max( size.height * (CGFloat(data) / CGFloat(maximum)), 2)
            
            view.frame = CGRect(
                x: (barWidth + padding) * CGFloat(index),
                y: -15,
                width: barWidth,
                height: size.height - barHeight + 15
            )            
        })
        
        zip(data, stepLabelViews).enumerated().map(prepend).forEach({ index, data, view in
            let labelWidth = CGFloat(140.0)
            let labelHeight = CGFloat(70.0)
            view.clipsToBounds = false
            if index < 4 {
                view.frame = CGRect(
                    x: -5,
                    y: -35,
                    width: labelWidth,
                    height: labelHeight
                )
            }
            else if index > 19 {
                view.frame = CGRect(
                    x: size.width - labelWidth + 5,
                    y: -35,
                    width: labelWidth,
                    height: labelHeight
                )
            }
            else {
                view.frame = CGRect(
                    // center about the bar
                    x: ((barWidth + padding) * CGFloat(index)) - labelWidth/2.0 + barWidth/2.0,
                    y: -35,
                    width: labelWidth,
                    height: labelHeight
                )
            }
            
        })
        
        zip(dotViews, dots).enumerated().map(prepend).forEach({ index, dotView, dot in
            dotView.frame = CGRect(
                x: (barWidth + padding) * CGFloat(index),
                y: size.height + 4.0,
                width: barWidth,
                height: 4.0
            )
            
            dotView.addSubview(dot)
            dot.autoCenterInSuperview()
        })
        
        zip(data, starViews).enumerated().map(prepend).forEach({ index, data, starView in
            let barHeight = max( size.height * (CGFloat(data) / CGFloat(maximum)), 2)

            starView.frame = CGRect(
                x: ((barWidth + padding) * CGFloat(index)) + 1.5,
                y: size.height - barHeight - 15,
                width: barWidth - 3,
                height: 13
            )
        })
        
        zip(data, sunViews).enumerated().map(prepend).forEach({ index, data, sunView in
            let barHeight = max( size.height * (CGFloat(data) / CGFloat(maximum)), 2)
            
            sunView.frame = CGRect(
                x: ((barWidth + padding) * CGFloat(index)) + 1.5,
                y: size.height - barHeight - 15,
                width: barWidth - 3,
                height: 13
            )
        })
        
        let pointsPerValue = size.height / CGFloat(maximum)

        labelViews.forEach({ view in
            let viewSize = view.systemLayoutSizeFitting(CGSize.max)
            let yOffset = round(pointsPerValue * CGFloat(view.number))

            view.frame = CGRect(
                x: 0,
                y: size.height - yOffset - viewSize.height,
                width: size.width,
                height: viewSize.height
            )
        })
    }
    
    /// Current hour is white and marked with a dot.
    func colorCurrentHour(hour: Int)
    {
        barViews[hour].backgroundColor = .white
        dots[hour].layer.backgroundColor = UIColor.white.cgColor
        if hour+1 < 23 {
            for time in hour+1 ... 23 {
                barViews[time].backgroundColor = UIColor(white: 1.0, alpha: 0.15)
            }
        }
    }
    
    /// Creates string for current hour's steps.
    func currentHourSteps(hour: Int)
    {
        barShadowViews[hour].isHidden = false
        stepLabelViews[hour].isHidden = false
        stepLabelViews[hour].transform = CGAffineTransform(translationX: 0, y: -55)
        let time = convertToStandardTime(hour: hour)
        let steps = data?[hour] ?? 0
        let stepsString = time + "\n" + String(steps) + " STEPS"
        func attributes(_ string: AttributedStringProtocol) -> NSAttributedString
        {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 1.2
            paragraphStyle.alignment = .center
            paragraphStyle.maximumLineHeight = 25
            return string.attributes(
                font: UIFont.gothamBook(14),
                paragraphStyle: paragraphStyle,
                tracking: 250
            )
        }
        stepLabelViews[hour].timeLabel.attributedText = attributes(stepsString)
    }
    
    func createToolbarTip(hour: Int) -> UIView
    {
        let containerView = UIView.newAutoLayout()
        
        func getToolbarShape(hour: Int) -> ShapeView {
            if hour == 0 { return ShapeView.tooltipBox(carotPosition: 1) }
            else if hour == 1 { return ShapeView.tooltipBox(carotPosition: 2) }
            else if hour == 2 { return ShapeView.tooltipBox(carotPosition: 3) }
            else if hour == 3 { return ShapeView.tooltipBox(carotPosition: 4) }
            else if hour == 23 { return ShapeView.tooltipBox(carotPosition: 9) }
            else if hour == 22 { return ShapeView.tooltipBox(carotPosition: 8) }
            else if hour == 21 { return ShapeView.tooltipBox(carotPosition: 7) }
            else if hour == 20 { return ShapeView.tooltipBox(carotPosition: 6) }
            else { return ShapeView.tooltipBox(carotPosition: 5) }
        }
        let toolbar = getToolbarShape(hour: hour)
        toolbar.autoSetDimensions(to: CGSize.init(width: 90, height: 40))
        containerView.addSubview(toolbar)
        containerView.sizeToFit()
        return containerView
    }
}

private final class ActivityDayGraphLabelView: UIView
{
    // MARK: - Display
    var number: Int = 0
        {
        didSet
        {
            label.attributedText = String(number).attributes(font: UIFont.gothamBook(12))
        }
    }
    
    // MARK: - Subviews
    fileprivate let label = UILabel.newAutoLayout()
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        label.textColor = .white
        addSubview(label)
        
        let separator = UIView.newAutoLayout()
        separator.backgroundColor = UIColor(white: 1.0, alpha: 0.25)
        addSubview(separator)
        
        label.autoPinEdgeToSuperview(edge: .top)
        label.autoPinEdgeToSuperview(edge: .leading)
        
        separator.autoPin(edge: .top, to: .bottom, of: label, offset: 2)
        separator.autoPinEdgesToSuperviewEdges(excluding: .top)
        separator.autoSet(dimension: .height, to: ActivityDayGraphCell.lineThickness)
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
}


private final class ActivityDayHourLabelView: UIView
{
    // MARK: - Subviews
    fileprivate let timeLabel = UILabel.newAutoLayout()
    fileprivate let stepsLabel = UILabel.newAutoLayout()
    fileprivate let boxView = UIView.newAutoLayout()
    fileprivate var tooltip : ShapeView?
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        addSubview(tooltip!)
        tooltip!.autoPinEdgesToSuperviewEdges()
        
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.numberOfLines = 2
        addSubview(timeLabel)
        timeLabel.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        timeLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 8)
    }
    
    init(hour: Int)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 140, height: 70))
        self.tooltip = getToolbarShape(hour: hour)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    func getToolbarShape(hour: Int) -> ShapeView {
        if hour == 0 { return ShapeView.tooltipBox(carotPosition: 0) }
        else if hour == 1 { return ShapeView.tooltipBox(carotPosition: 1) }
        else if hour == 2 { return ShapeView.tooltipBox(carotPosition: 2) }
        else if hour == 3 { return ShapeView.tooltipBox(carotPosition: 3) }
        else if hour == 23 { return ShapeView.tooltipBox(carotPosition: 10) }
        else if hour == 22 { return ShapeView.tooltipBox(carotPosition: 9) }
        else if hour == 21 { return ShapeView.tooltipBox(carotPosition: 8) }
        else if hour == 20 { return ShapeView.tooltipBox(carotPosition: 7) }
        else { return ShapeView.tooltipBox(carotPosition: 5) }
    }
}

extension Array where Element: UIView
{
    fileprivate mutating func match(_ count: Int, makeElement: (Int) -> Element)
    {
        while self.count < count
        {
            let view = makeElement(self.count)
            append(view)
        }

        while self.count > count
        {
            removeLast().removeFromSuperview()
        }
    }
}
