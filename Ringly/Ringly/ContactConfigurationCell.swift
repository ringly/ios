import ReactiveSwift
import RinglyExtensions

/// Includes the methods required for delegates of `ContactConfigurationCell` objects.
protocol ContactConfigurationCellDelegate: class
{
    /**
     Notifies the delegate that the user selected a new color for the contact configuration.
     
     - parameter cell:   The cell.
     - parameter color:  The new color.
     - parameter method: The method with which the new color was selected.
     */
    func contactConfigurationCell(_ cell: ContactConfigurationCell,
                                  selectedColor color: DefaultColor,
                                  withMethod method: ColorSliderViewSelectionMethod)

    /**
     Notifies the delegate that the user has requested to delete the contact configuration.
     
     - parameter cell: The cell.
     */
    func contactConfigurationCellDeleteContact(_ cell: ContactConfigurationCell)
}

/// A cell for displaying and modifying a `ContactConfiguration` value.
final class ContactConfigurationCell: ColorSliderCell
{
    // MARK: - Delegation
    /// The delegate of this cell
    weak var delegate: ContactConfigurationCellDelegate?
    
    // MARK: - Contact Configuration
    /// The contact configuration displayed by this cell.
    let contactConfiguration = MutableProperty<ContactConfiguration?>(nil)
    
    // MARK: - Deleting
    /// If true, this contact shows the "deleting" interface.
    let deleting = MutableProperty(false)
    
    // MARK: - Initialization
    fileprivate func setupContactConfigurationCell()
    {
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.clear
        selectionStyle = .none
        
        // wrap "slidable" content
        let innerContent = UIView.newAutoLayout()
        contentView.addSubview(innerContent)
        
        // add an icon
        let icon = UIImageView.newAutoLayout()
        icon.layer.cornerRadius = 20
        icon.layer.masksToBounds = true
        icon.layer.borderWidth = 1
        icon.layer.borderColor = UIColor.white.cgColor
        innerContent.addSubview(icon)
        
        // add label
        let label = UILabel.newAutoLayout()
        label.font = UIFont.gothamBook(13)
        label.textColor = UIColor.white
        label.highlightedTextColor = UIColor.white
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        innerContent.addSubview(label)
        
        // deletion button
        let delete = UIButton.newAutoLayout()
        delete.contentEdgeInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 13)
        delete.addTarget(self, action: #selector(ContactConfigurationCell.deleteAction), for: .touchUpInside)
        delete.setImage(UIImage(asset: .contactCellDelete), for: UIControlState())
        contentView.addSubview(delete)
        
        // deletion confirmation button
        let deleteConfirm = UIButton.newAutoLayout()
        deleteConfirm.addTarget(self, action: #selector(ContactConfigurationCell.deleteConfirmAction), for: .touchUpInside)

        let deleteFont = UIFont.gothamBook(13)
        deleteConfirm.setAttributedTitle(
            deleteFont.track(.controlsTracking, " REMOVE ").attributes(color: .white),
            for: .normal
        )

        deleteConfirm.setBackgroundImage(UIImage.rly_pixel(with: UIColor.ringlyRed), for: .normal)
        deleteConfirm.setBackgroundImage(UIImage.rly_pixel(with: UIColor.ringlyLightBlack), for: .highlighted)
        contentView.addSubview(deleteConfirm)
        
        // delete blocker
        let deleteBlocker = UIControl.newAutoLayout()
        deleteBlocker.addTarget(self, action: #selector(ContactConfigurationCell.deleteCancelAction), for: .touchUpInside)
        innerContent.addSubview(deleteBlocker)
        
        // layout
        innerContent.autoPinEdgeToSuperview(edge: .top)
        innerContent.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        innerContent.autoPin(edge: .trailing, to: .leading, of: deleteConfirm)
        innerContent.autoMatch(dimension: .width, to: .width, of: contentView, offset: -ColorSliderCell.sideInset)
        
        icon.autoPinEdgeToSuperview(edge: .leading, inset: 15)
        icon.autoSetDimensions(to: CGSize(width: 40, height: 40))
        icon.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        label.autoPin(edge: .leading, to: .trailing, of: icon, offset: 13)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        delete.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        delete.autoPin(edge: .leading, to: .trailing, of: label, offset: 0, relation: .greaterThanOrEqual)
        delete.autoPinEdgeToSuperview(edge: .top)
        delete.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        delete.autoPin(edge: .trailing, to: .trailing, of: innerContent, offset: -ColorSliderCell.sideInset)
        
        deleteBlocker.autoPinEdgesToSuperviewEdges()
        
        deleteConfirm.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        deleteConfirm.autoPin(edge: .leading, to: .trailing, of: label, offset: 0, relation: .greaterThanOrEqual)
        deleteConfirm.autoPinEdgeToSuperview(edge: .top)
        deleteConfirm.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        
        let confirmShown = deleteConfirm.autoPin(edge: .trailing, to: .trailing, of: contentView)
        let confirmHidden = deleteConfirm.autoPin(edge: .leading, to: .trailing, of: contentView)
        
        // bind contact information
        contactConfiguration.producer.startWithValues({ [weak self] contact in
            icon.image = contact?.image ?? UIImage(asset: .defaultContact)

            label.attributedText = (contact?.displayName.uppercased()).map({ name in
                label.font.track(.controlsTracking, name).attributedString
            })

            self?.colorSliderView.selectedColor = contact?.color ?? .none
        })
        
        // bind delete state
        deleting.producer.startWithValues({ [weak self] deleting in
            // hide and disable slider in deletion mode
            self?.colorSliderView.alpha = deleting ? 0 : 1
            self?.colorSliderView.isUserInteractionEnabled = !deleting
            
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

        // color slider view callback
        colorSliderView.selectedColorChanged = { [weak self] color, method in
            guard let strong = self else { return }
            strong.delegate?.contactConfigurationCell(strong, selectedColor: color, withMethod: method)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContactConfigurationCell()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setupContactConfigurationCell()
    }
    
    // MARK: - Cell
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        deleting.value = false
        delegate = nil
    }
    
    // MARK: - Actions
    @objc fileprivate func deleteAction()
    {
        UIView.animate(withDuration: 0.33, animations: {
            self.deleting.value = true
            self.layoutIfNeeded()
        })
    }
    
    @objc fileprivate func deleteConfirmAction()
    {
        delegate?.contactConfigurationCellDeleteContact(self)
    }
    
    @objc fileprivate func deleteCancelAction()
    {
        UIView.animate(withDuration: 0.33, animations: {
            self.deleting.value = false
            self.layoutIfNeeded()
        })
    }
}
