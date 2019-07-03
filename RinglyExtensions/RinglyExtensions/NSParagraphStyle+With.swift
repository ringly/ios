import Foundation

extension NSParagraphStyle
{
    
    @nonobjc public static func with(alignment: NSTextAlignment) -> NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return style
    }

    
    @nonobjc public static func with(lineSpacing: CGFloat) -> NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        return style
    }

    
    @nonobjc public static func with(alignment: NSTextAlignment, lineSpacing: CGFloat) -> NSParagraphStyle
    {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineSpacing = lineSpacing
        return style
    }
    
    public static var centeredBody: NSParagraphStyle {
        return .with(alignment: .center, lineSpacing: 8)
    }
    
    public static var centeredTitle: NSParagraphStyle {
        return .with(alignment: .center, lineSpacing: 3)
    }
}
