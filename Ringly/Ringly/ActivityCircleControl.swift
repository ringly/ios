import ReactiveSwift
import UIKit
import RinglyExtensions

final class ActivityCircleControl: UIControl
{
    // MARK: - Data

    /// Determines whether the value text or a prompt is displayed.
    let showValueText = MutableProperty(true)

    /// The value text displayed below the `icon`.
    let valueText = MutableProperty(ActivityControlValueText?.none)
    let valueType = MutableProperty(String?.none)
    

    // MARK: - Initialization
    fileprivate func setup()
    {
        self.layer.borderWidth = 6
        self.layer.borderColor = UIColor.init(white: 0.95, alpha: 1.0).cgColor
        
        // update background color based on current state
        showValueText.producer.or(reactive.highlighted).startWithValues({ [weak self] in
            self?.backgroundColor = $0 ? UIColor.white : UIColor(white: 1, alpha: 0.8)
        })
        
        // a container for centering the content
        let valueTextView = ActivityProgressControlContentView.newAutoLayout()
        valueTextView.isUserInteractionEnabled = false
        addSubview(valueTextView)
        valueTextView.autoCenterInSuperview()
        valueTextView.autoMatch(dimension: .width, to: .width, of: self, multiplier: 0.8)
        valueTextView.autoMatch(dimension: .height, to: .height, of: self, multiplier: 0.8)
        
        valueText.producer.combineLatest(with: self.valueType.producer.skipNil()).map({ valueText, valueType in
            return valueText ?? ActivityControlValueText.withUnit("--", valueType)
        }).startCrossDissolve(in: valueTextView.value, duration: 0.25) { (valueText) in
            switch valueText {
            case .withUnit(let value, let label):
                let screenOffset:CGFloat = DeviceScreenHeight.current.select(four: 0, five: 0, six: 6, sixPlus: 6, preferred: 0)
                var valueFontSize:CGFloat = 16
                
                if value.characters.count > 4 {
                    valueFontSize = 12
                } else if value.characters.count > 3 {
                    valueFontSize = 13
                }
                
                let valueSize = valueFontSize + screenOffset
                
                valueTextView.value.attributedText = UIFont.gothamBook(valueSize).track(150, value).attributedString
                valueTextView.title.attributedText = UIFont.gothamBook(12).track(150, label).attributedString

            default:
                break
            }
        }
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
    @nonobjc static let widthHeight = DeviceScreenHeight.current.select(four: 80.0, five: 80.0, six: 100.0, sixPlus: 100.0, preferred: 100.0)
    @nonobjc static let size = CGSize(width: ActivityCircleControl.widthHeight, height: ActivityCircleControl.widthHeight)

    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2
    }
}
