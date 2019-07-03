import Foundation

// MARK: - Base Protocol
public protocol AttributedStringProtocol
{
    var attributedString: NSAttributedString { get }
}

extension NSAttributedString: AttributedStringProtocol
{
    public var attributedString: NSAttributedString { return self }
}

extension String: AttributedStringProtocol
{
    public var attributedString: NSAttributedString { return NSAttributedString(string: self) }
}

// MARK: - Sequences
extension Sequence where Iterator.Element == AttributedStringProtocol
{
    public func join() -> NSAttributedString
    {
        let result = NSMutableAttributedString()
        lazy.map({ $0.attributedString }).forEach(result.append)
        return result
    }
}

// MARK: - Adding Attributes
extension AttributedStringProtocol
{
    public func attributes(color: UIColor? = nil,
                           font: UIFont? = nil,
                           paragraphStyle: NSParagraphStyle? = nil,
                           tracking: CGFloat? = nil,
                           underlined: Bool)
        -> NSAttributedString
    {
        let result = self.attributes(color: color, font: font, paragraphStyle: paragraphStyle, tracking: tracking) as! NSMutableAttributedString
        let range = NSRange(location: 0, length: result.length)

        result.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: range)
        
        return result
    }
    
    public func attributes(color: UIColor? = nil,
                           font: UIFont? = nil,
                           paragraphStyle: NSParagraphStyle? = nil,
                           tracking: CGFloat? = nil)
        -> NSAttributedString
    {
        let result = NSMutableAttributedString(attributedString: self.attributedString)
        let range = NSRange(location: 0, length: result.length)

        if let color = color
        {
            result.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }

        if let font = font
        {
            result.addAttribute(NSFontAttributeName, value: font, range: range)

            if let tracking = tracking
            {
                result.addAttribute(NSKernAttributeName, value: tracking * font.pointSize / 1000, range: range)
            }
        }

        if let paragraphStyle = paragraphStyle
        {
            result.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)
        }

        return result
    }
}
