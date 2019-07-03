import ReactiveSwift
import RinglyExtensions
import UIKit
import enum Result.NoError

/// To send and receive time information from MindfulSettingsViewController
protocol MindfulnessTimeDelegate : class
{
    func updateTime(time: Date)
}


final class MindfulTimeViewController: ServicesViewController, MindfulnessTimeDelegate
{
    /// The view for setting the reminder time.
    let timeSection = MindfulTimeView.newAutoLayout()
    
    weak var changeTimeDelegate : MindfulTimeSelectDelegate?
    
    // MARK: - Initialization
    override func loadView()
    {
        let view = UIView()
        self.view = view
        
        self.changeTimeDelegate = self.parent as! MindfulTimeSelectDelegate?

        let services = self.services
        
        // functions for spacer views
        func space(_ height: CGFloat) -> UIView
        {
            let view = UIView.newAutoLayout()
            view.autoSet(dimension: .height, to: height)
            return view
        }
        
        func titleLabel(_ text: String) -> UIView
        {
            let label = UILabel.newAutoLayout()
            label.textColor = .white
            label.textAlignment = .center
            label.attributedText = UIFont.gothamBook(15).track(150, text).attributedString
            return label
        }
        
        // create views for section titles and time picker
        let sectionViews = MindfulTime.sections.map({ title, mindfulTime in
            (
                titleLabel: titleLabel(title),
                mindfulTime: mindfulTime
                    .map({ mindfulTime -> (MindfulTime, MindfulTimeView) in
                        let view = timeSection
                        view.title = mindfulTime.title
                        return (mindfulTime, view)
                    })
            )
        })
        
        let switchSpace: CGFloat = 32
        
        sectionViews.enumerated().forEach({ sectionIndex, section in
            section.mindfulTime.enumerated().forEach({ switchIndex, mindfulTime in
                let spaceView = space(switchSpace)
                view.addSubview(spaceView)
                spaceView.autoPinEdgeToSuperview(edge: .top)
                spaceView.autoPinEdgeToSuperview(edge: .leading)
                spaceView.autoPinEdgeToSuperview(edge: .trailing)
                
                view.addSubview(mindfulTime.1)
                mindfulTime.1.autoPin(edge: .top, to: .bottom, of: spaceView)
                mindfulTime.1.autoPinEdgeToSuperview(edge: .leading)
                mindfulTime.1.autoPinEdgeToSuperview(edge: .trailing)
                
                let spaceView2 = space(switchSpace)
                view.addSubview(spaceView2)
                spaceView2.autoPin(edge: .top, to: .bottom, of: mindfulTime.1)
                spaceView2.autoPinEdgeToSuperview(edge: .leading)
                spaceView2.autoPinEdgeToSuperview(edge: .trailing)
                spaceView2.autoPinEdgeToSuperview(edge: .bottom)
            })
        })
        
        let dateFormat = DateFormatter(format: "h:mm a")
        let date = Calendar.current.date(from: services.preferences.mindfulReminderTime.value) ?? Date()
        let descriptionText = dateFormat.string(from: date)
        timeSection.timeSelected.attributedText = UIFont.gothamBook(15).track(150, descriptionText).attributedString
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let changing:((Any)->Void) = { [weak self] _ in
            self?.changeTimeDelegate?.showDatePicker()
        }
        timeSection.changeTimeButton.reactive.controlEvents(.touchUpInside).observe(changing)
    }
    
    internal func updateTime(time: Date) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let descriptionText = dateFormatter.string(from: time)
        timeSection.timeSelected.attributedText = UIFont.gothamBook(15).track(150, descriptionText).attributedString
        
        let newTime = Calendar.current.dateComponents([.hour, .minute], from: time)

        services.preferences.mindfulReminderTime.value = DateComponents.init(hour: newTime.hour, minute: newTime.minute)
    }
}

final class MindfulTimeView: UIView
{
    
    /// The label displaying the switch's title.
    let titleLabel = UILabel.newAutoLayout()
    
    /// The button to tap to change the time
    let changeTimeButton = UIButton.newAutoLayout()
    
    let timeSelected = UILabel.newAutoLayout()
    
    // MARK: - Content
    
    /// The title of the switch.
    var title: String?
        {
        get { return titleLabel.attributedText?.string }
        set
        {
            titleLabel.attributedText = newValue.map({ text in
                text.attributes(
                    font: .gothamBook(15),
                    paragraphStyle: .with(alignment: .left),
                    tracking: 160
                )
            })
        }
    }
    
    // MARK: - Initialization
    fileprivate func setup()
    {
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        timeSelected.textAlignment = .right
        
        changeTimeButton.addSubview(timeSelected)
        timeSelected.autoPin(edge: .top, to: .top, of: changeTimeButton)
        timeSelected.autoPin(edge: .left, to: .left, of: changeTimeButton)
        timeSelected.autoCenterInSuperview()
        timeSelected.backgroundColor = .clear
        timeSelected.textColor = .white
        
        // center all elements vertically in this view
        [ titleLabel, changeTimeButton].forEach({ view in
            addSubview(view)
            view.autoFloatInSuperview(alignedTo: .horizontal)
        })
        
        // title label fixed size
        titleLabel.autoSet(dimension: .width, to: 150)
        
        
        // the change time button has a fixed size
        changeTimeButton.autoPin(edge: .leading, to: .trailing, of: titleLabel, offset: 18)
        changeTimeButton.autoPinEdgeToSuperview(edge: .trailing)
        changeTimeButton.autoAlign(axis: .horizontal, toSameAxisOf: titleLabel)
        
        // set up horizontal arrangement of elements
        titleLabel.autoPinEdgeToSuperview(edge: .leading)
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

/// MindfulTime Section for Mindfulness Settings
enum MindfulTime
{
    case reminderTime
}

extension MindfulTime
{
    static var all: [MindfulTime]
    {
        return  [.reminderTime]
    }
    
    /// All preferences, in presentation order, grouped into sections.
    static var sections: [(title: String, description: [MindfulTime])]
    {
        return [
            (title: "Reminder Time", description: [
                .reminderTime
                ])
        ]
    }
}

extension MindfulTime
{
    // MARK: - Display Attributes
    
    /// The title for the preference.
    var title: String
    {
        switch self
        {
        case .reminderTime:
            return "Reminder Time"
        }
    }
}

extension MindfulTime
{
    // MARK: - Preferences
    
    /**
     Returns the property in the specified preferences object that is associated with the preference.
     
     - parameter preferences: The preferences object.
     */
    func property(in preferences: Preferences) -> MutableProperty<DateComponents>
    {
        switch self
        {
        case .reminderTime:
            return preferences.mindfulReminderTime
        }
    }
}
