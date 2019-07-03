import Foundation
import RinglyExtensions

extension AttributedStringProtocol
{
    /// An attributed string formatted for the "title" content of onboarding view controllers.
    var attributedOnboardingTitleString: NSAttributedString
    {
        return attributes(
            color: .white,
            font: .gothamBook(21),
            paragraphStyle: .with(alignment: .center, lineSpacing: 5),
            tracking: 250
        )
    }

    /// An attributed string formatted for the "detail" content of onboarding view controllers.
    var attributedOnboardingDetailString: NSAttributedString
    {
        return attributes(
            color: .white,
            font: .gothamBook(15),
            paragraphStyle: .with(alignment: .center, lineSpacing: 2.5),
            tracking: 30
        )
    }
}
