import ReactiveSwift
import UIKit

/// A view controller displaying preference switches.
final class ActivitySwitchViewController: ServicesViewController
{
    // MARK: - Initialization
    override func loadView()
    {
        let services = self.services
        
        // functions for stack view utilities
        func space(_ height: CGFloat) -> UIView
        {
            let view = UIView.newAutoLayout()
            view.autoSet(dimension: .height, to: height)
            return view
        }
        
        // create views for section titles and reminder switches
        let sectionSwitch = ActivitySwitch.all.map({ activitySwitch -> (ActivitySwitch, SettingsSwitchView) in
            let view = SettingsSwitchView.newAutoLayout()
            view.title = activitySwitch.title
            return (activitySwitch, view)
        })
        
        // start binding producers for switches
        SignalProducer.merge(
            sectionSwitch.flatMap({ activitySwitch, view in
                view.bindProducer(activitySwitch: activitySwitch, to: services.preferences)
            })
            ).take(until: reactive.lifetime.ended).start()
        
        let stack = UIStackView.newAutoLayout()
        stack.axis = .vertical
        stack.alignment = .fill
        
        sectionSwitch.enumerated().forEach({ sectionIndex, activitySwitch in
            stack.addArrangedSubview(space(10))
            stack.addArrangedSubview(activitySwitch.1)
            stack.addArrangedSubview(space(20))
        })
        
        // inset the edges of the stack
        let view = UIView()
        view.addSubview(stack)
        stack.autoPinEdgeToSuperview(edge: .leading)
        stack.autoPinEdgeToSuperview(edge: .trailing)
        stack.autoPinEdgeToSuperview(edge: .top, inset: 10)
        stack.autoPinEdgeToSuperview(edge: .bottom, inset: 10)
        self.view = view
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // when preferences change, write analytics event
        let producers = ActivitySwitch.all.map({ activitySwitch in
            activitySwitch.property(in: services.preferences).producer
                .skip(first: 1)
                .map({ (activitySwitch, $0) })
        })
        
        let analytics = services.analytics
        
        SignalProducer.merge(producers)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ activitySwitch, value in
                analytics.track(AnalyticsEvent.changedSetting(
                    setting: activitySwitch.analyticsSetting,
                    value: value
                ))
            })
        
    }
}
