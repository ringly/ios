import PureLayout
import UIKit

final class DiamondActivityIndicator
    : DisplayLinkView
{
    // MARK: - Appearances
    enum Appearance
    {
        case normal
        case simple
    }

    var color : UIColor = UIColor.init(white: 1.0, alpha: 1.0)
    
    /// The appearance of the activity indicator.
    var appearance = Appearance.normal
    {
        didSet
        {
            updatePolygons()
        }
    }

    // MARK: - Subviews
    
    /// The top facet views of the diamond activity indicator.
    fileprivate var polygonViews: (top: [UIView], bottom: [UIView])?
    {
        didSet
        {
            if let old = oldValue
            {
                (old.top + old.bottom).forEach({ $0.removeFromSuperview() })
            }

            if let new = polygonViews
            {
                (new.top + new.bottom).forEach({
                    container.addSubview($0)
                    $0.autoPinEdgesToSuperviewEdges()
                })
            }
        }
    }

    fileprivate func updatePolygons()
    {
        let polygons = appearance.polygons

        polygonViews = (
            top: polygons.top.map({ points in DiamondActivityViewFacet.viewWithPoints(points, color: self.color) }),
            bottom: polygons.bottom.map({ points in DiamondActivityViewFacet.viewWithPoints(points, color: self.color) })
        )
    }

    fileprivate let container = UIView.newAutoLayout()
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        // add a container view for facets, to maintain aspect ratio
        addSubview(container)
        
        // constrain aspect ratio of diamond
        container.autoConstrain(attribute: .height, to: .width, of: container, multiplier: 0.7068965517)
        
        // center diamond
        container.autoCenterInSuperview()
        
        // ideally pin diamond to all edges
        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            container.autoPinEdgesToSuperviewEdges()
        })
        
        // force diamond inside edges
        container.autoPinEdgeToSuperview(edge: .leading, inset: 0, relation: .greaterThanOrEqual)
        container.autoPinEdgeToSuperview(edge: .trailing, inset: 0, relation: .greaterThanOrEqual)
        container.autoPinEdgeToSuperview(edge: .top, inset: 0, relation: .greaterThanOrEqual)
        container.autoPinEdgeToSuperview(edge: .bottom, inset: 0, relation: .greaterThanOrEqual)
    }
    
    convenience init(color: UIColor)
    {
        self.init()
        self.color = color
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

    /// Constrains the view to the standard size. By default, the view does not have a size specified.
    func constrainToDefaultSize()
    {
        autoSetDimensions(to: CGSize(width: 87, height: 61.5))
    }
    
    // MARK: - Animation
    override func didMoveToWindow()
    {
        if window != nil && polygonViews == nil
        {
            updatePolygons()
        }

        super.didMoveToWindow()
    }
    
    override func displayLinkCallback(_ displayLink: CADisplayLink)
    {
        // calculate a value from 0-1 for the current progress of the animation loop
        let base = fmod(displayLink.timestamp, DiamondActivityIndicator.animationPeriod)
            / DiamondActivityIndicator.animationPeriod
        
        // set the individual view alphas
        if let (topViews, bottomViews) = polygonViews
        {
            DiamondActivityIndicator.animateViews(topViews, base: 1 - base, function: DiamondActivityIndicator.topCurve)
            DiamondActivityIndicator.animateViews(bottomViews, base: base, function: DiamondActivityIndicator.bottomCurve)
        }
    }

    /**
     Animates the specified views.

     - parameter views:    The views to animate.
     - parameter base:     A value from 0-1, to indicate the current animation position.
     - parameter function: A function to make the current progress to an alpha value.
     */
    fileprivate static func animateViews(_ views: [UIView], base: Double, function: (Double) -> CGFloat)
    {
        let offsetPerView = 1 / Double(views.count)
        
        for (index, view) in views.enumerated()
        {
            let offset = fmod(base + offsetPerView * Double(index), 1)
            view.alpha = minAlpha + function(offset) * (maxAlpha - minAlpha)
        }
    }

    /// The minimum alpha of a facet.
    fileprivate static let minAlpha: CGFloat = 0.6

    /// The maximum alpha of a facet.
    fileprivate static let maxAlpha: CGFloat = 0.9

    /// The amount of time in which a complete loop of the animation is completed.
    fileprivate static let animationPeriod: TimeInterval = 1

    /// The animation curve for the top views.
    fileprivate static func topCurve(_ offset: Double) -> CGFloat
    {
        return CGFloat((sin(offset * M_PI * 2) + 1) / 2)
    }

    /// The animation curve for the bottom views.
    fileprivate static func bottomCurve(_ offset: Double) -> CGFloat
    {
        return CGFloat((sin(offset * M_PI * 2) + 1) / 2)
    }
}

extension DiamondActivityIndicator.Appearance
{
    fileprivate var polygons: (top: [[CGPoint]], bottom: [[CGPoint]])
    {
        switch self
        {
        case .normal:
            // MARK: - Draw Constants - Top Triangles

            /// The Y-offset for the bottom of the upward-facing top triangles.
            let bottomOfUpwardTop: CGFloat = 0.2846

            /// The Y-Offset for the bottom of the downward-facing top triangles.
            let bottomOfDownwardTop: CGFloat = 0.2683

            /// The top point of the first top triangle.
            let topFirstTop = CGPoint(x: 0.1264, y: 0.02846)

            /// The top point of the first top triangle.
            let topFirstLeft = CGPoint(x: 0, y: bottomOfUpwardTop)

            /// The right point of the first top triangle.
            let topFirstRight = CGPoint(x: 0.2126, y: bottomOfUpwardTop)

            /// The left point of the second top triangle.
            let topSecondLeft = CGPoint(x: 0.1552, y: 0)

            /// The right point of the second top triangle.
            let topSecondRight = CGPoint(x: 0.3736, y: 0)

            /// The bottom point of the second top triangle.
            let topSecondBottom = CGPoint(x: 0.2385, y: bottomOfDownwardTop)

            /// The left point of the third top triangle.
            let topThirdLeft = CGPoint(x: 0.2644, y: bottomOfUpwardTop)

            /// The right point of the third top triangle.
            let topThirdRight = CGPoint(x: 0.4799, y: bottomOfUpwardTop)

            /// The top point of the third top triangle.
            let topThirdTop = CGPoint(x: 0.3937, y: 0.02846)
            
            /// The left point of the middle top triangle.
            let topMiddleLeft = CGPoint(x: 0.41954, y: 0)
            
            /// The bottom point of the middle top triangle.
            let topMiddleBottom = CGPoint(x: 0.5, y: 0.2602)

            // MARK: - Draw Constants - Bottom Triangles

            /// The top of the bottom triangles.
            let topOfBottom: CGFloat = 0.3252

            /// The left point of the first bottom triangle.
            let bottomFirstLeft = CGPoint(x: 0, y: topOfBottom)

            /// The right point of the first bottom triangle.
            let bottomFirstRight = CGPoint(x: 0.2299, y: topOfBottom)

            /// The bottom point of the first bottom triangle.
            let bottomFirstBottom = CGPoint(x: 0.4540, y: 0.9839)

            /// The left point of the second bottom triangle.
            let bottomSecondLeft = CGPoint(x: 0.2586, y: topOfBottom)

            /// The right point of the second bottom triangle.
            let bottomSecondRight = CGPoint(x: 0.4856, y: topOfBottom)
            
            /// The bottom point of the second bottom triangle.
            let bottomSecondBottom = CGPoint(x: 0.4856321839, y: 1)

            return (
                top: [
                    [topFirstTop, topFirstLeft, topFirstRight],
                    [topSecondLeft, topSecondRight, topSecondBottom],
                    [topThirdLeft, topThirdRight, topThirdTop],
                    [topMiddleLeft, topMiddleBottom, flip(topMiddleLeft)],
                    [flip(topThirdLeft), flip(topThirdRight), flip(topThirdTop)],
                    [flip(topSecondLeft), flip(topSecondRight), flip(topSecondBottom)],
                    [flip(topFirstTop), flip(topFirstLeft), flip(topFirstRight)]
                ],
                bottom: [
                    [bottomFirstLeft, bottomFirstRight, bottomFirstBottom],
                    [bottomSecondLeft, bottomSecondRight, bottomSecondBottom],
                    [flip(bottomFirstLeft), flip(bottomFirstRight), flip(bottomFirstBottom)],
                    [flip(bottomSecondLeft), flip(bottomSecondRight), flip(bottomSecondBottom)]
                ]
            )
        case .simple:
            // MARK: - Draw Constants

            let middleRightOfFirst: CGFloat = 0.26
            let middleLeftOfSecond: CGFloat = 0.34

            // MARK: - Draw Constants - Top Quadrangles

            /// The bottom coordinate of the top quadrangles.
            let bottomOfTop: CGFloat = 0.295

            let topFirstLeft = CGPoint(x: 0.2, y: 0)
            let topFirstRight = CGPoint(x: 0.36, y: 0)
            let topFirstBottomLeft = CGPoint(x: 0, y: bottomOfTop)
            let topFirstBottomRight = CGPoint(x: middleRightOfFirst, y: bottomOfTop)

            let topSecondLeft = CGPoint(x: 0.42, y: 0)
            let topSecondBottomLeft = CGPoint(x: middleLeftOfSecond, y: bottomOfTop)

            /// MARK: - Draw Constants - Bottom Triangles

            /// The top coordinate of the bottom triangles.
            let topOfBottom: CGFloat = 0.364

            /// The left point of the first bottom triangle.
            let bottomFirstLeft = CGPoint(x: 0, y: topOfBottom)

            /// The right point of the first bottom triangle.
            let bottomFirstRight = CGPoint(x: middleRightOfFirst, y: topOfBottom)

            /// The bottom point of the first bottom triangle.
            let bottomFirstBottom = CGPoint(x: 0.44, y: 1)

            let bottomSecondLeft = CGPoint(x: middleLeftOfSecond, y: topOfBottom)
            
            /// The bottom point of the second bottom triangle.
            let bottomSecondBottom = CGPoint(x: 0.5, y: 1)

            return (
                top: [
                    [topFirstLeft, topFirstRight, topFirstBottomRight, topFirstBottomLeft],
                    [topSecondLeft, flip(topSecondLeft), flip(topSecondBottomLeft), topSecondBottomLeft],
                    [flip(topFirstLeft), flip(topFirstRight), flip(topFirstBottomRight), flip(topFirstBottomLeft)]
                ],
                bottom: [
                    [bottomFirstLeft, bottomFirstRight, bottomFirstBottom],
                    [bottomSecondLeft, flip(bottomSecondLeft), bottomSecondBottom],
                    [flip(bottomFirstLeft), flip(bottomFirstRight), flip(bottomFirstBottom)]
                ]
            )
        }
    }
}

/// A view for an individual facet of a `DiamondActivityView`.
private final class DiamondActivityViewFacet: UIView
{
    /**
     Creates a facet view with the specified triangle.
     
     - parameter triangle: The triangle to use.
     */
    fileprivate static func viewWithPoints(_ points: [CGPoint], color: UIColor) -> DiamondActivityViewFacet
    {
        let view = DiamondActivityViewFacet.newAutoLayout()
        view.backgroundColor = UIColor.clear
        view.points = points
        view.color = color
        return view
    }
    
    /// The points displayed by this facet view.
    fileprivate var points: [CGPoint]?
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    fileprivate var color: UIColor = UIColor.init(white: 1.0, alpha: 1.0)
    
    fileprivate override func draw(_ rect: CGRect)
    {
        guard let points = self.points, let context = UIGraphicsGetCurrentContext() else { return }
        
        let size = bounds.size

        if let first = points.first
        {
            context.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
        }

        points.dropFirst().forEach({ point in
            context.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
        })

        context.closePath()
        
        context.setFillColor(self.color.cgColor)
        context.fillPath()
    }
}

// MARK: - Draw Utilities
private func flip(_ point: CGPoint) -> CGPoint
{
    return CGPoint(x: 1 - point.x, y: point.y)
}
