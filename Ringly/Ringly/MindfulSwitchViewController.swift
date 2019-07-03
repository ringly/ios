import ReactiveSwift
import UIKit

/// A view controller displaying preference switches.
final class MindfulSwitchViewController: ServicesViewController
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
        let sectionSwitch = MindfulSwitch.all.map({ mindfulSwitch -> (MindfulSwitch, SettingsSwitchView) in
                let view = SettingsSwitchView.newAutoLayout()
                view.title = mindfulSwitch.title
                return (mindfulSwitch, view)
        })
        
        // start binding producers for switches
        SignalProducer.merge(
            sectionSwitch.flatMap({ mindfulSwitch, view in
                    view.bindProducer(mindfulSwitch: mindfulSwitch, to: services.preferences)
                })
        ).take(until: reactive.lifetime.ended).start()
        
        let stack = UIStackView.newAutoLayout()
        stack.axis = .vertical
        stack.alignment = .fill
        
        sectionSwitch.enumerated().forEach({ sectionIndex, mindfulSwitch in
                stack.addArrangedSubview(space(10))
                stack.addArrangedSubview(mindfulSwitch.1)
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
        let producers = MindfulSwitch.all.map({ mindfulSwitch in
            mindfulSwitch.property(in: services.preferences).producer
                .skip(first: 1)
                .map({ (mindfulSwitch, $0) })
        })
        
        let analytics = services.analytics
        
        SignalProducer.merge(producers)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ mindfulSwitch, value in
                analytics.track(AnalyticsEvent.changedSetting(
                    setting: mindfulSwitch.analyticsSetting,
                    value: value
                ))
            })

    }
}
