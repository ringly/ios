import Foundation

/// A field included in a multipart HTTP body.
public struct MultipartField
{
    // MARK: - Initialization

    /// Initializes a multipart field.
    ///
    /// - Parameters:
    ///   - name: The name of the field.
    ///   - value: The value of the field.
    public init(name: String, value: String)
    {
        self.name = name
        self.value = value
    }

    // MARK: - Properties

    /// The name of the field.
    fileprivate let name: String

    /// The value of the field.
    fileprivate let value: String
}

/// A file included in a multipart HTTP body.
public struct MultipartFile
{
    // MARK: - Initialization

    /// Initializes a file value.
    ///
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - mime: The MIME type of the file.
    ///   - data: The data to upload for the file.
    public init(name: String, mime: String, data: Data)
    {
        self.name = name
        self.mime = mime
        self.data = data
    }

    /// Initializes a file value.
    ///
    /// - Parameters:
    ///   - name: The name of the file.
    ///   - mime: The MIME type of the file.
    ///   - contents: A string to convert to UTF-8 data to upload for the file.
    public init?(name: String, mime: String, contents: String)
    {
        guard let data = contents.data(using: .utf8) else { return nil }
        self.init(name: name, mime: mime, data: data)
    }

    // MARK: - Properties

    /// The name of the file.
    public let name: String

    /// The MIME type of the file.
    public let mime: String

    /// The data to upload for the file.
    public let data: Data
}

extension Data
{
    /// Initializes a data value for `multipart/form-data` upload.
    ///
    /// - Parameters:
    ///   - multipartFields: The fields to include in the data.
    ///   - multipartFiles: The files to include in the data.
    ///   - boundary: The boundary to use to separate elements of the data.
    init(multipartFields: [MultipartField], multipartFiles: [MultipartFile], boundary: String)
    {
        var data = Data()

        multipartFields.forEach({ field in
            data.append("--\(boundary)\r\n")
            data.append("Content-Disposition: form-data; name=\(field.name.quoted)\r\n\r\n")
            data.append("\(field.value)\r\n")
        })

        multipartFiles.enumerated().forEach({ index, file in
            let name = "file_\(index)"
            data.append("--\(boundary)\r\n")
            data.append("Content-Disposition: form-data; name=\(name.quoted); filename=\(file.name.quoted)\r\n")
            data.append("Content-Type: \(file.mime)\r\n\r\n")
            data.append(file.data)
            data.append("\r\n")
        })

        data.append("--\(boundary)--\r\n")

        self = data
    }
}

extension Data
{
    fileprivate mutating func append(_ string: String)
    {
        if let data = string.data(using: .utf8)
        {
            append(data)
        }
    }
}

extension String
{
    fileprivate var quoted: String { return "\"\(self)\"" }
}
