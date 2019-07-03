import AVFoundation
import ReactiveSwift
import UIKit

class ShareView : UIView
{
    
    // title of view
    private let titleLabel = UILabel.newAutoLayout()
    let title: String = "SHARE WITH FRIENDS"
    
    // back button
    let backButton : UIButton = UIButton.newAutoLayout()
    
    // share button
    let shareButton : UIButton = UIButton.newAutoLayout()

    // image and caption view container
    let imageContainer : UIView = UIView.newAutoLayout()
    
    // title of view
    let caption : UITextField = UITextField.newAutoLayout()
    let defaultCaption : String = "Write a caption!"
    var editTextField : Bool = false
    
    // exit button to go back to developer
    var imageView : UIImageView = UIImageView.newAutoLayout()
    var imageWidth : CGFloat?
    var isZoomed : Bool = false
    
    // initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    // setup of view
    private func setup()
    {
        
        let font = UIFont.gothamBook(20)
        
        // setup title label
        titleLabel.attributedText = title.attributes(font: font, tracking: .controlsTracking)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 2
        titleLabel.isUserInteractionEnabled = false
        self.addSubview(titleLabel)
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 35)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        // setup back button
        backButton.setImage(UIImage(asset: .navigationBackArrow), for: .normal)
        backButton.showsTouchWhenHighlighted = true
        self.addSubview(backButton)
        backButton.autoPinEdgeToSuperview(edge: .left, inset: 30)
        backButton.autoPinEdgeToSuperview(edge: .top, inset: 50)
        
        // share button
        shareButton.clipsToBounds = true
        shareButton.setImage(UIImage(asset: .share), for: .normal)
        shareButton.showsTouchWhenHighlighted = true
        self.addSubview(shareButton)
        shareButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
        shareButton.autoPin(edge: .leading, to: .trailing, of: titleLabel, offset: 15)
        shareButton.autoPinEdgeToSuperview(edge: .trailing, inset: 25)
        shareButton.autoAlign(axis: .horizontal, toSameAxisOf: backButton)
        
        // setup imageContainer view
        self.addSubview(imageContainer)
        
        imageView.backgroundColor = UIColor.ringlyLightBlack.withAlphaComponent(0.4)
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.contentMode = .scaleAspectFit
        imageContainer.addSubview(imageView)
        imageView.autoPinEdgeToSuperview(edge: .top, inset: 25)
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        let zoomImage = UITapGestureRecognizer(target: self, action: #selector(ShareView.zoomImage))
        zoomImage.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(zoomImage)

        
        // setup caption label
        caption.font = font.withSize(14)
        caption.textColor = UIColor.white
        caption.placeholder = defaultCaption
        caption.adjustsFontSizeToFitWidth = false
        imageContainer.addSubview(caption)
        caption.autoPin(edge: .top, to: .bottom, of: imageView, offset: 10)
        caption.autoPinEdgeToSuperview(edge: .left, inset: 25)
        caption.autoPinEdgeToSuperview(edge: .right, inset: 25)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        let center = NotificationCenter.default
        
        let forceHidden = Signal.merge(
            center.reactive.notifications(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: caption)
                .map({ _ in false }),
            center.reactive.notifications(forName: Notification.Name.UITextFieldTextDidEndEditing, object: caption)
                .map({ _ in true })
        )
        
        SignalProducer(forceHidden).combineLatest(with: caption.reactive.allTextValues)
            .map({ force, text in force || text?.characters.count ?? 0 == 0 })
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak caption] mode in
                guard let strongField = caption else { return }
                strongField.rightView?.isHidden = mode
            })
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ShareView.editText))
//        imageContainer.addGestureRecognizer(tapGesture)
        
    }
    
    
    func editText()
    {
        caption.isEnabled = true
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        imageContainer.autoSet(dimension: .width, to: 500, relation: .lessThanOrEqual)
        imageContainer.autoSet(dimension: .height, to: 500, relation: .lessThanOrEqual)
        
        imageContainer.autoMatch(dimension: .height, to: .width, of: imageContainer)
        imageContainer.autoPinEdgeToSuperview(edge: .leading)
        imageContainer.autoPinEdgeToSuperview(edge: .trailing)
        imageContainer.autoAlignAxis(toSuperviewAxis: .horizontal)

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            (200...500).forEach({ offset in
                imageContainer.autoSet(dimension: .width, to: CGFloat(offset), relation: .greaterThanOrEqual)
            })
        })
        
        imageView.autoConstrain(attribute: .width, to: .width, of: imageContainer, multiplier: 0.35)
        imageView.autoConstrain(attribute: .height, to: .width, of: self.imageView)
        
        imageWidth = imageView.frame.width
        
        caption.autoConstrain(attribute: .height, to: .width, of: imageContainer, multiplier: 0.4)
    }
    
    func zoomImage(image : UIImage)
    {
        if !isZoomed {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                self.imageView.transform = CGAffineTransform(scaleX: self.imageContainer.frame.width, y: self.imageContainer.frame.width)
            }, completion: nil)
        }
        else {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                self.imageView.transform = CGAffineTransform(scaleX: self.imageWidth!, y: self.imageWidth!)
            }, completion: nil)
        }
        isZoomed = !isZoomed
    }
    
    func setImage(image : UIImage)
    {
        self.imageView.image = image
    }
    
    func textFieldDidEndEditing(textField : UITextField)
    {
        //init later
    }
    

}
