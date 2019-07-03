import RealmSwift

final class LoggingMessage: Object
{
    // MARK: - Initialization

    /// Initializes a logging message with all properties.
    ///
    /// - Parameters:
    ///   - text: The text of the log message.
    ///   - type: The type of log message.
    ///   - date: The date that the log message was recorded.
    convenience init(text: String, type: RLogType, date: Date)
    {
        self.init()
        self.text = text
        self.type = type
        self.date = date
    }

    // MARK: - Properties

    /// The text of the log message.
    dynamic var text: String?

    /// A backing property for `type`.
    dynamic fileprivate var _type: Int = 0

    /// The type of log message.
    var type: RLogType?
    {
        get { return RLogType(rawValue: _type) }
        set { _type = newValue?.rawValue ?? 0 }
    }

    /// The date that the log message was recorded.
    dynamic var date: Date?

    // MARK: - Equality

    /// Log messages are equal if their `text`, `type`, and `date` properties are equal.
    ///
    /// - Parameter object: The other object.
    /// - Returns: `true` if the objects are equal, otherwise `false`.
    override func isEqual(_ object: Any?) -> Bool
    {
        guard let other = object as? LoggingMessage else { return false }
        return text == other.text && _type == other._type && date == other.date
    }
}

extension LoggingMessage: CommaSeparatedValueRepresentable
{
    static var commaSeparatedHeaders: [String]
    {
        return ["Date", "Type", "Message"]
    }

    var commaSeparatedFields: [String]
    {
        let formatter = DateFormatter(format: "yyyy-MM-dd HH:mm:ss.SSS")

        return [
            formatter.string(from: date!),
            RLogTypeToString(type!),
            text!
        ]
    }
}

