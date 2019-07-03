import Foundation

extension DateFormatter
{
    /// Initializes a date formatter with a date format.
    ///
    /// - Parameter format: The date format to use.
    convenience init(format: String)
    {
        self.init()
        self.dateFormat = format
    }

    /// Initializes a date formatter with a localized format template.
    ///
    /// - Parameter localizedFormatTemplate: The localized format template to use.
    convenience init(localizedFormatTemplate: String)
    {
        self.init()
        setLocalizedDateFormatFromTemplate(localizedFormatTemplate)
    }
}
