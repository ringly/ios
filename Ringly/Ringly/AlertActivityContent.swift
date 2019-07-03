import UIKit

enum ActivityIndicatorType {
    case none
    case ui
    case emoji(symbol:String)
}

struct AlertActivityContent
{
    /// The title text to display.
    let text: String?
    fileprivate let activityIndicatorType:ActivityIndicatorType
    
    init(text: String, activityIndicatorType:ActivityIndicatorType) {
        self.text = text
        self.activityIndicatorType = activityIndicatorType
    }
}

extension AlertActivityContent: AlertViewControllerContent
{
    var alertContentView: UIView
    {
        let foregroundColor = UIColor(white: 0.2, alpha: 1.0)

        let stack = UIStackView.newAutoLayout()
        stack.alignment = .center
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.autoSet(dimension: .width, to: 216)

        // insert a spacer view at the top of the hierarchy
        func spacer(_ height: CGFloat) -> UIView
        {
            let view = UIView.newAutoLayout()
            view.autoSet(dimension: .height, to: 40)
            return view
        }

        stack.addArrangedSubview(spacer(40))

        // add the image view if an image was specified
        if let text = self.text
        {
            let textLabel = UILabel.newAutoLayout()
            textLabel.attributedText = text.alertTextAttributedString
            textLabel.numberOfLines = 0
            textLabel.textColor = foregroundColor

            stack.addArrangedSubview(textLabel)
        }

        // add an activity indicator below the optional text
        switch self.activityIndicatorType {
        case .ui:
            let activity = UIActivityIndicatorView.newAutoLayout()
            activity.activityIndicatorViewStyle = .gray
            activity.startAnimating()
            stack.addArrangedSubview(spacer(40))
            stack.addArrangedSubview(activity)
            stack.addArrangedSubview(spacer(40))
        case .emoji(let emoji):
            let emojiLabel = UILabel()
            emojiLabel.text = emoji
            emojiLabel.font = UIFont.systemFont(ofSize: 72)
            emojiLabel.textAlignment = .center
            stack.addArrangedSubview(spacer(20))
            stack.addArrangedSubview(emojiLabel)
            stack.addArrangedSubview(spacer(20))
        case .none:
            break
        }


        return stack
    }
}

extension String
{
    fileprivate var textAttributedString: NSAttributedString
    {
        return centeredAttributedString(15, tracking: 150, lineSpacing: 3)
    }

    fileprivate var detailTextAttributedString: NSAttributedString
    {
        return centeredAttributedString(12, tracking: 150, lineSpacing: 3)
    }

    fileprivate func centeredAttributedString(_ size: CGFloat, tracking: CGFloat, lineSpacing: CGFloat)
        -> NSAttributedString
    {
        return attributes(
            font: .gothamBook(size),
            paragraphStyle: .with(alignment: .center, lineSpacing: lineSpacing),
            tracking: tracking
        )
    }
}
