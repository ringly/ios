import Foundation

/// A protocol for types that can be represented as a comma-separated value row.
protocol CommaSeparatedValueRepresentable
{
    /// The headers for a comma-separated representation of a sequence of values.
    static var commaSeparatedHeaders: [String] { get }

    /// The comma-separated value fields of this value.
    var commaSeparatedFields: [String] { get }
}

extension Sequence where Iterator.Element: CommaSeparatedValueRepresentable
{
    /**
     A comma-separated-values representation of the sequence's elements, derived from each element's `fields`.

     - parameter headers: Values for the header row.
     */
    var commaSeparatedValueRepresentation: String
    {
        let escapedHeaders = Iterator.Element.commaSeparatedHeaders
            .map({ $0.commaSeparatedValueEscapedString })
            .joined(separator: ",")

        return ([escapedHeaders] + map({ $0.commaSeparatedValueRepresentation })).joined(separator: "\n")
    }
}

extension CommaSeparatedValueRepresentable
{
    /// A comma-separated-values representation of the receiver, derived from `fields`.
    var commaSeparatedValueRepresentation: String
    {
        return commaSeparatedFields.map({ $0.commaSeparatedValueEscapedString }).joined(separator: ",")
    }
}

extension String
{
    /// Escapes the string for usage in comma-separated values.
    fileprivate var commaSeparatedValueEscapedString: String
    {
        let replaced = self.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(replaced)\""
    }
}
