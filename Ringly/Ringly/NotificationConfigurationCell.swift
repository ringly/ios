import Contacts
import PureLayout
import ReactiveSwift
import RinglyActivityTracking
import RinglyExtensions
import RinglyKit
import UIKit
import enum Result.NoError


/// Includes the methods required for delegates of `NotificationConfigurationCell` objects.
protocol NotificationConfigurationCellDelegate: class
{
    /**
     Notifies the delegate that the user has requested to delete the notification configuration.
     
     - parameter cell: The cell.
     */
    func notificationConfigurationDeleteCell(cell: NotificationConfigurationCell)
}


final class NotificationConfigurationCell: UITableViewCell
{
    // Cell overview
    weak var delegate: NotificationConfigurationCellDelegate?
    
    
    // Notification Properties
    struct Properties {
        let notificationAlert : NotificationAlert
        let applications : ApplicationsService
        let contacts : CNContactStore
    }
    let properties = MutableProperty<Properties?>(nil)
    
    
    // Editing the cell
    let deleting = MutableProperty(false)
    

    // Subviews
    private let titleLabel = UILabel.newAutoLayout()
    private let dateLabel = UILabel.newAutoLayout()
    private let messageLabel = UILabel.newAutoLayout()
    private let icon = UIImageView.newAutoLayout()
    
    
    // Initialization
    private func setupNotification()
    {
        // Background Setup
        self.backgroundColor = .clear
        self.contentView.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.separatorInset = .zero
        
        let innerContent = UIView.newAutoLayout()
        innerContent.backgroundColor = UIColor.clear
        contentView.addSubview(innerContent)
        
        // Notification Parts: Icon, Title, Date, Message
        icon.layer.cornerRadius = 20
        icon.layer.masksToBounds = true
        innerContent.addSubview(icon)
        
        titleLabel.font = UIFont.gothamBook(16)
        titleLabel.textColor = UIColor.white
        titleLabel.highlightedTextColor = UIColor.magenta
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textAlignment = .left
        innerContent.addSubview(titleLabel)
        
        dateLabel.font = UIFont.gothamBook(15)
        dateLabel.textColor = UIColor.white
        dateLabel.highlightedTextColor = UIColor.magenta
        dateLabel.backgroundColor = UIColor.clear
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.8
        dateLabel.numberOfLines = 1
        dateLabel.lineBreakMode = .byTruncatingTail
        dateLabel.textAlignment = .right
        innerContent.addSubview(dateLabel)
        
        messageLabel.font = UIFont.gothamBook(14)
        messageLabel.textColor = UIColor.white
        messageLabel.highlightedTextColor = UIColor.magenta
        messageLabel.backgroundColor = UIColor.clear
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.minimumScaleFactor = 0.8
        innerContent.addSubview(messageLabel)

        // delete button
        let delete = UIButton.newAutoLayout()
        delete.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        delete.addTarget(self, action: #selector(NotificationConfigurationCell.deleteAction), for: .touchUpInside)
        contentView.addSubview(delete)
        
        // delete confirmation button
        let deleteConfirm = UIButton.newAutoLayout()
        deleteConfirm.addTarget(self, action: #selector(NotificationConfigurationCell.deleteConfirmAction), for: .touchUpInside)
        let deleteFont = UIFont.gothamBook(13)
        deleteConfirm.setAttributedTitle(deleteFont.track(.controlsTracking, " REMOVE ").attributes(color: .white), for: .normal)
        deleteConfirm.setBackgroundImage(UIImage.rly_pixel(with: UIColor.ringlyRed), for: .normal)
        deleteConfirm.setBackgroundImage(UIImage.rly_pixel(with: UIColor.ringlyLightBlack), for: .highlighted)
        contentView.addSubview(deleteConfirm)
        
        // delete blocker
        let deleteBlocker = UIControl.newAutoLayout()
        deleteBlocker.addTarget(self, action: #selector(NotificationConfigurationCell.deleteCancelAction), for: .touchDown)
        innerContent.addSubview(deleteBlocker)
        
        // Pinning Organizing Views
        innerContent.autoPinEdgeToSuperview(edge: .top)
        innerContent.autoPinEdgeToSuperview(edge: .bottom)
        innerContent.autoPin(edge: .trailing, to: .leading, of: deleteConfirm)
        innerContent.autoMatch(dimension: .width, to: .width, of: contentView)
        
        icon.autoPinEdgeToSuperview(edge: .leading, inset: 15)
        icon.autoSetDimensions(to: CGSize(width: 40, height: 40))
        icon.autoAlignAxis(toSuperviewAxis: .horizontal)
        icon.contentMode = .scaleToFill

        titleLabel.autoPin(edge: .leading, to: .trailing, of: icon, offset: 10)
        titleLabel.autoPin(edge: .trailing, to: .leading, of: dateLabel, offset: 15)
        titleLabel.autoPinEdgeToSuperview(edge: .top, inset: 20)

        messageLabel.autoPinEdgeToSuperview(edge: .trailing, inset: 15)
        messageLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 10)
        messageLabel.autoPin(edge: .top, to: .bottom, of: dateLabel, offset: 10)
        messageLabel.autoPin(edge: .leading, to: .trailing, of: icon, offset: 10)
        messageLabel.autoPinEdgeToSuperview(edge: .bottom, inset: 20)

        dateLabel.autoPinEdgeToSuperview(edge: .trailing, inset: 15)
        dateLabel.autoPinEdgeToSuperview(edge: .top, inset: 20)
        
        delete.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        delete.autoPin(edge: .leading, to: .trailing, of: messageLabel, offset: -200)
        delete.autoPinEdgeToSuperview(edge: .top)
        delete.autoPinEdgeToSuperview(edge: .bottom)
        delete.autoPin(edge: .trailing, to: .trailing, of: innerContent, offset: -ColorSliderCell.sideInset)
        
        deleteBlocker.autoPinEdgesToSuperviewEdges()
        
        deleteConfirm.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        deleteConfirm.autoPin(edge: .leading, to: .trailing, of: messageLabel, offset: 0, relation: .greaterThanOrEqual)
        deleteConfirm.autoPinEdgeToSuperview(edge: .top)
        deleteConfirm.autoPinEdgeToSuperview(edge: .bottom)
        
        let confirmShown = deleteConfirm.autoPin(edge: .trailing, to: .trailing, of: contentView)
        let confirmHidden = deleteConfirm.autoPin(edge: .leading, to: .trailing, of: contentView)

        // bind configuration state
        properties.producer.startWithValues({ notification in
            let notif = notification?.notificationAlert
            self.titleLabel.text = notif?.title?.uppercased()
            self.dateLabel.text = (notif?.date as? Date).map(NotificationConfigurationCell.dateFormatter.string)
            self.messageLabel.text = notif?.message
            if let appScheme = notif?.application {
                let correspondingApp = notification?.applications.supportedApplications
                    .filter({$0.identifiers.contains(appScheme)})
                    .first
                
                // check if notification is from message, phone, or facetime and match contact image
                let appsToMatch = ["com.apple.MobileSMS", "com.apple.mobilephone", "com.apple.facetime"]
                var isContact : Bool = false
                
                let matchingIdentifier = correspondingApp?.identifiers.first ?? "noMatch"
                if appsToMatch.contains(matchingIdentifier) { isContact = true}
                
                // if a contact, set contact image
                if isContact {
                    self.icon.layer.borderWidth = 1
                    self.icon.layer.borderColor = UIColor.white.cgColor
                    
                    let predicate = CNContact.predicateForContacts(matchingName: (notif?.title)!)
                    let keys: [CNKeyDescriptor] = [
                        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactImageDataAvailableKey as CNKeyDescriptor,
                        CNContactThumbnailImageDataKey as CNKeyDescriptor
                    ]

                    do {
                        let matchingContacts = try notification?.contacts
                            .unifiedContacts(matching: predicate, keysToFetch: keys)
                            .filter({($0.displayName == notif?.title) || ($0.nickname == notif?.title)})
                            .first

                        self.icon.image = matchingContacts?.image ?? UIImage(asset: .defaultContact)
                    }
                    catch {
                        self.icon.image = UIImage(asset: .defaultContact)
                    }
                }
                // if not a contact, set app image
                else {
                    self.icon.layer.borderWidth = 0
                    let appImage = (correspondingApp?.scheme).flatMap({scheme in UIImage(named: scheme)})
                    self.icon.image = appImage ?? UIImage(asset: .ringGlossy)
                }
            }
            else {
                self.icon.image = UIImage(asset: .ringGlossy)
            }
        })

        // bind delete state
        deleting.producer.startWithValues({ deleting in
            // hide and disable delete button in deletion mode
            delete.alpha = deleting ? 0 : 1
            delete.isUserInteractionEnabled = !deleting
            
            // enable delete blocker in deletion mode
            innerContent.isUserInteractionEnabled = deleting
            deleteBlocker.isUserInteractionEnabled = deleting
            
            // show/hide delete confirm
            confirmShown.isActive = deleting
            confirmHidden.isActive = !deleting
        })
    }
    
    // Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupNotification()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setupNotification()
    }
    
    // Layout
    override func sizeThatFits(_ size: CGSize) -> CGSize
    {
        let fitSize = CGSize(width: size.width - 10, height: .greatestFiniteMagnitude)
        
        return CGSize(
            width: size.width,
            height: 50 + titleLabel.sizeThatFits(fitSize).height + messageLabel.sizeThatFits(fitSize).height
        )
    }
    
    // Cell
    override func prepareForReuse()
    {
        super.prepareForReuse()
        properties.value = nil
        deleting.value = false
        delegate = nil
    }
    
    // Actions
    @objc private func deleteAction()
    {
        UIView.animate(withDuration: 0.33, animations: {
            self.deleting.value = true
            self.layoutIfNeeded()
        })
    }
    
    @objc private func deleteConfirmAction()
    {
        delegate?.notificationConfigurationDeleteCell(cell: self)
    }
    
    @objc private func deleteCancelAction()
    {
        UIView.animate(withDuration: 0.33, animations: {
            self.deleting.value = false
            self.layoutIfNeeded()
        })
    }
    
    // Date Formatting
    private static let dateFormatter = DateFormatter(format: "MMM d h:mm a")
    
    // Image Resizing
    private func scaledImage(image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 20, height: 20), false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 20, height: 20))
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}


