import UIKit

final class ColorSliderView: UIView
{
    // MARK: - Callbacks
    var selectedColorChanged: ((DefaultColor, ColorSliderViewSelectionMethod) -> ())?

    // MARK: - Selected Color
    var selectedColor = DefaultColor.none
    {
        didSet
        {
            leftView.backgroundColor = UIColor.color(defaultColor: DefaultColorBefore(selectedColor))
            middleView.backgroundColor = UIColor.color(defaultColor: selectedColor)
            rightView.backgroundColor = UIColor.color(defaultColor: DefaultColorAfter(selectedColor))
        }
    }

    // MARK: - Subviews
    fileprivate let leftView = UIView()
    fileprivate let middleView = UIView()
    fileprivate let rightView = UIView()

    // MARK: - Initialization
    fileprivate func setup()
    {
        clipsToBounds = true

        [leftView, middleView, rightView].forEach({
            $0.isUserInteractionEnabled = false
            addSubview($0)
        })

        // add gesture recognizers for user interaction
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ColorSliderView.panAction(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(ColorSliderView.tapAction(_:)))
        addGestureRecognizer(tap)
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
    fileprivate var dragOffset: CGFloat = 0 { didSet { setNeedsLayout() } }

    override func layoutSubviews()
    {
        super.layoutSubviews()

        let bounds = self.bounds
        leftView.frame = bounds.offsetBy(dx: -bounds.size.width + dragOffset, dy: 0)
        middleView.frame = bounds.offsetBy(dx: dragOffset, dy: 0)
        rightView.frame = bounds.offsetBy(dx: bounds.size.width + dragOffset, dy: 0)
    }

    // MARK: - Gesture Recognizer Actions
    @objc fileprivate func panAction(_ sender: UIPanGestureRecognizer)
    {
        switch sender.state
        {
        case .changed:
            let translation = sender.translation(in: superview)

            // if the user is pulling more vertically than horizontally, terminate the gesture recognition
            if abs(translation.x) < abs(translation.y)
            {
                sender.isEnabled = false
                sender.isEnabled = true
            }
            else
            {
                dragOffset = translation.x
            }

        case .ended:
            let velocity = sender.velocity(in: self).x
            let translation = sender.translation(in: superview).x
            let width = bounds.size.width

            let enoughVelocity = abs(velocity) > 2
            let enoughTranslation = abs(translation / width) > 0.5
            let velocityPositive = velocity > 0
            let translationPositive = translation > 0
            let velocityAndTranslationSame = velocityPositive == translationPositive

            if (enoughVelocity || enoughTranslation) && velocityAndTranslationSame
            {
                let newColor = (velocityPositive ? DefaultColorBefore : DefaultColorAfter)(selectedColor)
                selectedColorChanged?(newColor, .pan)

                // initialize layout for animated transition
                dragOffset = translationPositive
                    ? translation - width
                    : translation + width

                layoutIfNeeded()

                // animate to the new color
                let duration = velocity != 0 ? min(0.5, abs(Double(dragOffset / velocity))) : 0.5

                UIView.animate(withDuration: duration, animations: {
                    UIView.setAnimationCurve(.easeOut)
                    self.dragOffset = 0
                    self.layoutIfNeeded()
                })
            }
            else
            {
                // if the user is dragging back, return at the velocity that they are dragging
                let userDraggingBack = velocityAndTranslationSame && velocity != 0
                let duration = userDraggingBack ? min(1, Double(translation / velocity)) : 0.25

                UIView.animate(withDuration: duration, animations: {
                    UIView.setAnimationCurve(userDraggingBack ? .easeOut : .easeInOut)
                    self.dragOffset = 0
                    self.layoutIfNeeded()
                })
            }

        case .cancelled, .failed:
            if dragOffset != 0
            {
                UIView.animate(withDuration: 0.25, animations: {
                    self.dragOffset = 0
                    self.layoutIfNeeded()
                })
            }

        case .began, .possible:
            break
        }
    }

    fileprivate var performingTapTransition = false

    @objc fileprivate func tapAction(_ sender: UITapGestureRecognizer)
    {
        // disallow performing multiple tap transitions at the same time
        guard !performingTapTransition else { return }
        performingTapTransition = true

        // initialize by transforming to the
        dragOffset = bounds.size.width
        layoutIfNeeded()

        selectedColorChanged?(DefaultColorAfter(selectedColor), .tap)

        UIView.animate(withDuration: 0.35, animations: {
            UIView.setAnimationCurve(.easeInOut)
            self.dragOffset = 0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.performingTapTransition = false
        })
    }
}

extension ColorSliderView: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        return otherGestureRecognizer is UIPanGestureRecognizer
            && !(otherGestureRecognizer is UIScreenEdgePanGestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

@objc enum ColorSliderViewSelectionMethod: Int
{
    case pan
    case tap
}
