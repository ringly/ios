import Foundation

/// The type for value text displayed on an activity control.
enum ActivityControlValueText
{
    /// The text is shown without a unit, in a large font.
    case standalone(String)

    /// The value is shown in a large font, followed by a unit in a small font.
    case withUnit(String, String)
}

/// The structure for data displayed by a circular activity control (`ActivityCircleControl` or
/// `ActivityProgressControl`).
struct ActivityControlData
{
    /// A value from `0` to `1`, indicating the current progress.
    let progress: CGFloat

    /// The text to display in the large label.
    let valueText: ActivityControlValueText?
}

extension ActivityControlValueText
{
    func attributedString(largeFont: UIFont, smallFont: UIFont) -> NSAttributedString
    {
        switch self
        {
        case .standalone(let text):
            return largeFont.track(50, text).attributedString
        case .withUnit(let value, let unit):
            return [
                largeFont.track(50, value + " "),
                smallFont.track(50, unit.uppercased())
            ].join().attributedString
        }
    }
    
    func valueLength() -> Int
    {
        switch self
        {
        case .standalone(let text):
            return text.characters.count
        case .withUnit(let value, _):
            return value.characters.count
        }
    }
}

extension ActivityControlValueText: Equatable {}
func ==(lhs: ActivityControlValueText, rhs: ActivityControlValueText) -> Bool
{
    switch (lhs, rhs)
    {
    case (.standalone(let lhsText), .standalone(let rhsText)):
        return lhsText == rhsText
    case (.withUnit(let lhsParams), .withUnit(let rhsParams)):
        return lhsParams == rhsParams
    default:
        return false
    }
}

