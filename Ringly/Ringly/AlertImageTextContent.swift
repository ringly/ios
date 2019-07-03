import UIKit

struct AlertImageTextContent
{
    /// The image to display above the text content.
    let image: UIImage?

    /// The title text to display.
    let text: String

    /// The detail text to display.
    let detailText: String
    
    let tinted:Bool
}

extension AlertImageTextContent
{
    /// Initializes an image text content with an error.
    ///
    /// - Parameters:
    ///   - image: The image to use. The default value of this parameter, if omitted, is `nil`.
    ///   - error: The error.
    init(image: UIImage? = nil, error: NSError)
    {
        self.init(
            image: image,
            text: error.localizedDescription,
            detailText: error.localizedFailureReason ?? "",
            tinted: true
        )
    }

    /// Initializes an image text content without an image.
    ///
    /// - Parameters:
    ///   - text: The title text to display.
    ///   - detailText: The detail text to display.
    init(text: String, detailText: String)
    {
        self.init(image: nil, text: text, detailText: detailText, tinted: false)
    }
    
    init(image: UIImage?, text: String, detailText: String)
    {
        self.init(image: image, text: text, detailText: detailText, tinted: true)
    }
}

extension AlertImageTextContent: AlertViewControllerContent
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
            view.autoSet(dimension: .height, to: height)
            return view
        }

        stack.addArrangedSubview(spacer(40))

        // add the image view if an image was specified
        if let image = self.image
        {
            let imageView = UIImageView()
            
            if self.tinted {
                imageView.image = image.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = foregroundColor
            } else {
                imageView.image = image
            }

            stack.addArrangedSubview(imageView)
            stack.addArrangedSubview(spacer(24))
        }

        // add the text label
        let textLabel = UILabel.newAutoLayout()
        textLabel.attributedText = text.alertTextAttributedString
        textLabel.numberOfLines = 0
        textLabel.textColor = foregroundColor

        stack.addArrangedSubview(textLabel)
        stack.addArrangedSubview(spacer(24))

        let detailTextLabel = UILabel.newAutoLayout()
        detailTextLabel.attributedText = detailText.alertDetailTextAttributedString
        detailTextLabel.numberOfLines = 0
        detailTextLabel.textColor = foregroundColor

        stack.addArrangedSubview(detailTextLabel)
        stack.addArrangedSubview(spacer(32))

        return stack
    }
}

extension String
{
    var alertTextAttributedString: NSAttributedString
    {
        return UIFont.gothamBook(15).track(.titleTracking, self)
            .attributes(paragraphStyle: .centeredTitle)
    }

    var alertDetailTextAttributedString: NSAttributedString
    {
        return UIFont.gothamBook(12).track(.bodyTracking, self)
            .attributes(paragraphStyle: .centeredBody)
    }
}
