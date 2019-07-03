import UIKit

/// Displays a control for adding an activity tracking body attribute in preferences.
final class PreferencesActivityAddControl: UIControl
{
    // MARK: - Initialization
    fileprivate func setup()
    {
        isAccessibilityElement = true
        autoSetEqualDimensions(to: 85)
        backgroundColor = .clear
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

    // MARK: - Appearance

    /// The title displayed by the button.
    var title: String?
    {
        didSet
        {
            setNeedsDisplay()
            accessibilityLabel = title.map({ "Add \($0)" })
        }
    }

    // MARK: - Highlighting
    override var isHighlighted: Bool { didSet { setNeedsDisplay() } }

    // MARK: - Drawing
    override func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let bounds = self.bounds

        // fill the control with a circle
        let color = isHighlighted ? ButtonControl.defaultHighlightedFillColor : ButtonControl.defaultFillColor
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: bounds)

        // from here on, draw cutouts
        context.setBlendMode(.destinationOut)

        // determine the dimensions of cutout elements
        let plusLength: CGFloat = 14
        let plusThickness: CGFloat = 2
        let innerPadding: CGFloat = 8

        let text = UIFont.gothamBook(12).track(250, title ?? "").attributedString
        let textSize = text.size()
        let contentHeight = plusLength + innerPadding + textSize.height

        // draw the title cutout in the control
        text.draw(at: CGPoint(
            x: bounds.midX - textSize.width / 2,
            y: bounds.midY + contentHeight / 2 - textSize.height
        ))

        // draw a plus sign cutout in the control
        UIBezierPath(
            roundedRect: CGRect(
                x: bounds.midX - plusThickness / 2,
                y: bounds.midY - contentHeight / 2,
                width: plusThickness,
                height: plusLength
            ),
            cornerRadius: plusThickness / 2
        ).fill()

        UIBezierPath(
            roundedRect: CGRect(
                x: bounds.midX - plusLength / 2,
                y: bounds.midY - contentHeight / 2 + plusLength / 2 - plusThickness / 2,
                width: plusLength,
                height: plusThickness
            ),
            cornerRadius: plusThickness / 2
        ).fill()
    }
}
