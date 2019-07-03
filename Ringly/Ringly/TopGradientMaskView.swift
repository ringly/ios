import ReactiveSwift
import UIKit

final class TopGradientMaskView: UIView
{
    // MARK: - Gradient Settings

    /// The maximum height of the mask gradient drawn.
    let maxGradientHeight = MutableProperty<CGFloat>(75)

    /// The current content offset of the scroll view this view is masking, determining the gradient's height.
    let contentOffset = MutableProperty<CGFloat>(0)

    /// The height to draw the gradient at.
    fileprivate let drawHeight = MutableProperty<CGFloat>(0)

    // MARK: - Gradient

    /// The gradient used for drawing the mask.
    fileprivate let gradient = CGGradient.create([
        (0, UIColor.clear),
        (1, UIColor.black)
    ])

    // MARK: - Initialization
    fileprivate func setup()
    {
        backgroundColor = .clear

        drawHeight <~ contentOffset.producer
            .combineLatest(with: maxGradientHeight.producer)
            .map({ contentOffset, maxGradientHeight in
                min(max(contentOffset, 0), maxGradientHeight)
            })

        drawHeight.signal.skipRepeats().observeValues({ [weak self] _ in self?.setNeedsDisplay() })
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

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext(), let gradient = self.gradient else { return }

        context.drawLinearGradient(gradient,
            start: .zero,
            end: CGPoint(x: 0, y: drawHeight.value),
            options: .drawsAfterEndLocation
        )
    }
}
