import PureLayout
import ReactiveSwift
import RinglyExtensions
import RinglyKit

// MARK: - Delegate Protocol

/// Enumerates methods of delegates of the `ApplicationConfigurationCell` class.
protocol ApplicationConfigurationCellDelegate: class
{
    /**
     Notifies the delegate that the user has requested a vibration pattern change via the cell's interface.
     
     - parameter cell:      The cell.
     - parameter vibration: The vibration pattern selected by the user.
     */
    func applicationConfigurationCell(_ cell: ApplicationConfigurationCell, didSetVibration vibration: RLYVibration)
    
    /**
     Notifies the delegate that the user has requested an LED color change via the cell's interface.
     
     - parameter cell:   The cell.
     - parameter color:  The color selected by the user.
     - parameter method: The method with which the new color was selected.
     */
    func applicationConfigurationCell(_ cell: ApplicationConfigurationCell,
                                      didSetColor color: DefaultColor,
                                      withMethod method: ColorSliderViewSelectionMethod)
}

// MARK: - Cell Class

/// Presents an `ApplicationConfiguration` structure in an interface, and allows the user to request alterations in the
/// configuration's settings, via a delegate protocol.
class ApplicationConfigurationCell: UITableViewCell
{
    // MARK: - Delegation
    /// The delegate for this cell.
    weak var delegate: ApplicationConfigurationCellDelegate?
    
    // MARK: - Properties
    /// The application configuration displayed by this cell.
    let configuration = MutableProperty<ApplicationConfiguration?>(nil)
    
    /// If the cell should display its "selection mode" interface.
    let inSelectionMode = MutableProperty(false)

    // MARK: - Initialization
    fileprivate let vibrationChooser = VibrationChooserView.newAutoLayout()
    
    fileprivate func setupApplicationConfigurationCell()
    {
        // overall cell style
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // color slider view
        let colorSlider = ColorSliderView.newAutoLayout()
        contentView.addSubview(colorSlider)

        colorSlider.autoPinEdgeToSuperview(edge: .top)
        colorSlider.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        colorSlider.autoMatch(
            dimension: .width,
            to: .width,
            of: contentView,
            offset: -2 * ColorSliderCell.sideInset
        )

        NSLayoutConstraint.autoSet(priority: UILayoutPriorityDefaultHigh, forConstraints: {
            colorSlider.autoPinEdgeToSuperview(edge: .leading, inset: ColorSliderCell.sideInset)
        })
        
        // checkbox view
        let checkbox = Checkbox.newAutoLayout()
        checkbox.isUserInteractionEnabled = false
        contentView.addSubview(checkbox)

        checkbox.autoPinEdgeToSuperview(edge: .top)
        checkbox.autoPinEdgeToSuperview(edge: .bottom, inset: ColorSliderCell.sideInset)
        checkbox.autoMatch(dimension: .width, to: .height, of: checkbox)
        checkbox.autoPin(edge: .trailing, to: .leading, of: colorSlider)
        let checkboxLeading = checkbox.autoPinEdgeToSuperview(edge: .leading)
        
        // icon view
        let iconContainer = UIView.newAutoLayout()
        contentView.addSubview(iconContainer)

        iconContainer.autoPin(edge: .top, to: .top, of: colorSlider)
        iconContainer.autoPin(edge: .bottom, to: .bottom, of: colorSlider)
        iconContainer.autoPin(edge: .leading, to: .leading, of: colorSlider)
        iconContainer.autoSet(dimension: .width, to: 66)
        
        let icon = UIImageView.newAutoLayout()
        iconContainer.addSubview(icon)
        icon.autoCenterInSuperview()
        
        // label
        let label = UILabel.newAutoLayout()
        label.isUserInteractionEnabled = false
        label.font = UIFont.gothamBook(13)
        label.textColor = UIColor.white
        label.highlightedTextColor = UIColor.white
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        contentView.addSubview(label)

        label.autoAlign(axis: .horizontal, toSameAxisOf: colorSlider)
        label.autoPin(edge: .leading, to: .trailing, of: iconContainer)
        label.autoPinEdgeToSuperview(edge: .trailing, inset: 10, relation: .greaterThanOrEqual)
        label.autoConstrain(attribute: .trailing, to: .trailing, of: colorSlider, multiplier: 0.8, relation: .lessThanOrEqual)
        
        // vibration chooser
        vibrationChooser.delegate = self
        contentView.addSubview(vibrationChooser)

        [ALEdge.leading, .trailing, .top, .bottom].forEach({ edge in
            vibrationChooser.autoPin(edge: edge, to: edge, of: colorSlider)
        })

        // when entering selection mode, update the interface
        inSelectionMode.producer
            .skipRepeats(==)
            .on(value: { [weak self] inSelectionMode in
                // show/hide color slider
                colorSlider.alpha = inSelectionMode ? 0 : 1
                self?.vibrationChooser.alpha = inSelectionMode ? 0 : 1
                checkbox.alpha = inSelectionMode ? 1 : 0
                
                // adjust constraints
                checkboxLeading.isActive = inSelectionMode
                
                self?.layoutIfInWindowAndNeeded()
            })
            .filter({ inSelectionMode in inSelectionMode }) // when we're transitioning into selection mode
            .on(value: { [weak self] _ in
                self?.collapseVibrationChooser()
            })
            .start()
        
        // hide interface elements when the vibration chooser is expanded
        let vibrationExpanded = vibrationChooser.expanded.producer

        vibrationExpanded.startWithValues({ expanded in
            icon.alpha = expanded ? 0 : 1
            label.alpha = expanded ? 0 : 1
        })
        
        // disable the color slider when other interface elements are activated
        vibrationExpanded.not.and(inSelectionMode.producer.not).startWithValues({ enabled in
            colorSlider.isUserInteractionEnabled = enabled
        })
        
        // react to configuration changes
        configuration.producer.startWithValues({ [weak self] configuration in
            // update checkbox state
            checkbox.checked = configuration?.activated ?? false
            
            // load the image based on the configuration's application's URL scheme
            icon.image = (configuration?.application.scheme).flatMap({ scheme in UIImage(named: scheme) })
            
            // update label text
            label.attributedText = (configuration?.application.name.uppercased()).map({ name in
                name.attributes(font: label.font, paragraphStyle: .with(lineSpacing: 3), tracking: 300)
            })
            
            // update selected vibration and color
            self?.vibrationChooser.selectedVibration.value = configuration?.vibration ?? .none
            colorSlider.selectedColor = configuration?.color ?? .none
        })

        // color slider view callbacks
        colorSlider.selectedColorChanged = { [weak self] color, method in
            guard let strong = self else { return }
            strong.delegate?.applicationConfigurationCell(strong, didSetColor: color, withMethod: method)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupApplicationConfigurationCell()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setupApplicationConfigurationCell()
    }
    
    // MARK: - Interface

    /// Collapses the cell's vibration chooser interface.
    @nonobjc func collapseVibrationChooser()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.vibrationChooser.expanded.value = false
            self.layoutIfNeeded()
        })
    }
}

// MARK: - VibrationChooserViewDelegate
extension ApplicationConfigurationCell: VibrationChooserViewDelegate
{
    func vibrationChooserViewRequestedExpansion(_ vibrationChooserView: VibrationChooserView)
    {
        UIView.animate(withDuration: 0.25, animations: {
            vibrationChooserView.expanded.value = true
            self.layoutIfNeeded()
        })
    }
    
    func vibrationChooserView(_ vibrationChooserView: VibrationChooserView, selectedVibration vibration: RLYVibration)
    {
        delegate?.applicationConfigurationCell(self, didSetVibration: vibration)
        self.collapseVibrationChooser()
    }
}
