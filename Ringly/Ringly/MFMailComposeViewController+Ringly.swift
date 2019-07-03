import MessageUI
import Result
import RinglyExtensions

extension UIViewController
{
    /// Presents an email prompt for sending data.
    ///
    /// - Parameters:
    ///   - description: A description of the content (e.g. “diagnostic data”).
    ///   - reference: An optional reference number, which will be included in the email body.
    ///   - recipients: The default recipients for the email.
    ///   - userEmail: The user's email address, if available.
    ///   - attach: A function to provide an attachment.
    @nonobjc func mail(description: String,
                       reference: String?,
                       recipients: [String],
                       userEmail: String?,
                       attach: () -> Result<MailComposeAttachment, NSError>)
    {
        let canSend: Result<(), NSError> = MFMailComposeViewController.canSendMail()
            ? .success(())
            : .failure(MailComposeError(
                errorDescription: "Mail Account Required",
                failureReason: "To send \(description), a Mail account is required."
            ) as NSError)

        switch canSend &&& attach()
        {
        case let .success(_, attachment):
            let compose = MFMailComposeViewController()
            compose.mailComposeDelegate = UIApplication.shared.delegate as? AppDelegate
            compose.setSubject("Ringly \(description)")
            compose.setToRecipients(recipients)

            let body = [
                "My Ringly \(description) is attached.",
                reference.map({ "My reference is “\($0)”." }),
                "Thanks!"
            ].flatMap({ $0 }).joined(separator: "\n\n")

            compose.setMessageBody(body, isHTML: false)

            let fileName = attachment.mailFilename(userEmail: userEmail)
            compose.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: fileName)

            present(compose, animated: true, completion: nil)

        case let .failure(error):
            self.presentError(error)
        }
    }
}

/// An attachment for `UIViewController`'s `mail(description:reference:recipients:attach:)` extension.
struct MailComposeAttachment
{
    /// The data to attach to the email.
    let data: Data

    /// The MIME type to set.
    let mimeType: String

    /// The base name for the file name. This will be transformed to include the user's email address, if possible.
    let fileNameBase: String

    /// The file extension to use.
    let fileExtension: String

    /// Attempts to gzip the attachment. If unsuccessful, returns `self`.
    func gzippedIfSuccessful() -> MailComposeAttachment
    {
        if let gzipped = try? (data as NSData).byGZipCompressing()
        {
            return MailComposeAttachment(
                data: gzipped,
                mimeType: "application/x-gzip",
                fileNameBase: fileNameBase,
                fileExtension: "gdata"
            )
        }
        else
        {
            return self
        }
    }

    /// Creates a file name for a mail attachment. Attempts to insert the user's email for identification.
    ///
    /// - Parameters:
    ///   - userEmail: The user's email.
    /// - Returns: A file name with the user's email inserted (`base-email.fileExtension`), or `base.fileExtension` if
    ///            the user's email cannot be accessed.
    fileprivate func mailFilename(userEmail: String?) -> String
    {
        return userEmail.map({ email in
            "\(fileNameBase)-\(email).\(fileExtension)"
        }) ?? "\(fileNameBase).\(fileExtension)"
    }
}

/// An error for `UIViewController`'s `mail(description:reference:recipients:attach:)` extension.
struct MailComposeError: CustomNSError, LocalizedError
{
    static let errorDomain = "MailComposeError"
    let errorCode = 0

    /// The error's title.
    let errorDescription: String?

    /// The error's message body.
    let failureReason: String?
}
