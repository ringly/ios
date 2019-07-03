import Foundation
import Result
import RinglyExtensions
import class DFULibrary.Zip

// MARK: - Unzipping

public protocol DFUUnzipProvider
{
    func zipDataFileURL() throws -> URL
}

extension DFUUnzipProvider
{
    /**
     Unzips the receiver to a temporary directory.

     - parameter prefix: A prefix for the directory name.
     */
    public func unzippedToTemporaryDirectory(prefix: String? = nil) -> Result<URL, NSError>
    {
        return Result(attempt: {
            let destination = try createTemporaryDirectory(prefix: prefix ?? "dfu")

            try Zip.unzipFile(
                self.zipDataFileURL(),
                destination: destination,
                overwrite: true,
                password: nil,
                progress: nil
            )

            return destination
        })
    }
}

extension Data: DFUUnzipProvider
{
    public func zipDataFileURL() throws -> URL
    {
        let fileURL = try createTemporaryDirectory().appendingPathComponent("data.zip", isDirectory: false)
        try write(to: fileURL, options: .atomic)
        return fileURL
    }
}

private func createTemporaryDirectory(prefix: String = "ringly") throws -> URL
{
    let temporary = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(prefix)-\(arc4random())")

    if !FileManager.default.rly_directoryExists(atPath: temporary.path)
    {
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true, attributes: nil)
    }

    return temporary
}
