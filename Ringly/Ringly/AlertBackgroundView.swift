import PureLayout
import RinglyAPI
import RinglyDFU
import UIKit

final class AlertBackgroundView: UIView
{
    // MARK: - Error
    var error: NSError? = nil
    {
        didSet
        {
            errorLabel.text = error.map({ error in
                "\(AlertBackgroundView.domainDisplayStringForError(error)) • \(error.code)"
            })
        }
    }

    static func domainDisplayStringForError(_ error: NSError) -> String
    {
        switch error.domain
        {
        case NSURLErrorDomain: return "0"
        case NSCocoaErrorDomain: return "1"
        case APIService.httpErrorDomain: return "4"
        case kDFUErrorDomain: return "5"
        case "com.ringly": return "6"
        // 7 was previously used for RACSignalErrorDomain, don't reuse
        case DFUWriteErrorDomain: return "8"
        default: return error.domain
        }
    }

    // MARK: - Subviews
    fileprivate let errorLabel = UILabel.newAutoLayout()

    // MARK: - Initialization
    fileprivate func setup()
    {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        addSubview(blurView)
        blurView.autoPinEdgesToSuperviewEdges()

        errorLabel.textColor = UIColor(white: 1, alpha: 0.1)
        errorLabel.font = UIFont.gothamBook(10)
        blurView.contentView.addSubview(errorLabel)

        errorLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        errorLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 10)
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
}
