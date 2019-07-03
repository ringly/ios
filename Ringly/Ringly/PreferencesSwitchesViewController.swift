import ReactiveSwift
import UIKit

/// A view controller displaying preference switches.
final class PreferencesSwitchesViewController: ServicesViewController
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

        func titleLabel(_ text: String) -> UIView
        {
            let label = UILabel.newAutoLayout()
            label.textColor = .white
            label.textAlignment = .center
            label.attributedText = UIFont.gothamBook(15).track(250, text).attributedString

            return label
        }

        // create views for section titles and preference switches
        let sectionViews = PreferencesSwitch.sections.map({ title, preferencesSwitches in
            (
                titleLabel: titleLabel(title),
                preferencesSwitches: preferencesSwitches
                    .map({ preferencesSwitch -> (PreferencesSwitch, PreferencesSwitchView) in
                        let view = PreferencesSwitchView.newAutoLayout()
                        view.title = preferencesSwitch.title
                        return (preferencesSwitch, view)
                    })
            )
        })

        // start binding producers for switches
        SignalProducer.merge(
            sectionViews.flatMap({ _, switches in
                switches.map({ preferencesSwitch, view in
                    view.bindProducer(preferencesSwitch: preferencesSwitch, to: services.preferences)
                })
            })
        ).take(until: reactive.lifetime.ended).start()

        // present pages view controller when "?" button is tapped
        let helpTappedProducer = SignalProducer.merge(
            sectionViews.flatMap({ _, switches in
                switches.map({ preferencesSwitch, view in
                    view.infoRequestedProducer.map({ _ in preferencesSwitch })
                })
            })
        )

        helpTappedProducer.startWithValues({ [weak self] preferencesSwitch in
            let pages = PreferencesSwitchesPagesViewController(services: services)
            pages.transitioningDelegate = OverlayPresentationTransition.sharedDelegate
            pages.modalPresentationStyle = .overFullScreen
            pages.visibleSwitch.value = preferencesSwitch
            self?.present(pages, animated: true, completion: nil)
        })

        // stack switches and titles
        let titleSpace: CGFloat = 44
        let switchSpace: CGFloat = 32

        let stack = UIStackView.newAutoLayout()
        stack.axis = .vertical
        stack.alignment = .fill

        sectionViews.enumerated().forEach({ sectionIndex, section in
            stack.addArrangedSubview(section.titleLabel)
            stack.addArrangedSubview(space(titleSpace))

            section.preferencesSwitches.enumerated().forEach({ switchIndex, preferencesSwitch in
                stack.addArrangedSubview(preferencesSwitch.1)

                if switchIndex < section.preferencesSwitches.count - 1
                {
                    stack.addArrangedSubview(space(switchSpace))
                }
            })

            if sectionIndex < sectionViews.count - 1
            {
                stack.addArrangedSubview(space(titleSpace))
                stack.addArrangedSubview(UIView.rly_separatorView(withHeight: 1, color: UIColor.white))
                stack.addArrangedSubview(space(titleSpace))
            }
        })

        // inset the edges of the stack
        let view = UIView()
        view.addSubview(stack)
        stack.autoPinEdgeToSuperview(edge: .leading)
        stack.autoPinEdgeToSuperview(edge: .trailing)
        stack.autoPinEdgeToSuperview(edge: .top, inset: 47)
        stack.autoPinEdgeToSuperview(edge: .bottom, inset: titleSpace)
        self.view = view
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // when preferences change, write analytics event
        let producers = PreferencesSwitch.all.map({ preferenceSwitch in
            preferenceSwitch.property(in: services.preferences).producer
                .skip(first: 1)
                .map({ (preferenceSwitch, $0) })
        })

        let analytics = services.analytics

        SignalProducer.merge(producers)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ preferencesSwitch, value in
                analytics.track(AnalyticsEvent.changedSetting(
                    setting: preferencesSwitch.analyticsSetting,
                    value: value
                ))
            })

        // when low battery is enabled, if necessary, prompt the user to enable notifications
        let preferences = services.preferences

        preferences.batteryAlertsEnabled.producer
            .skip(first: 1)
            .ignore(false)
            .take(until: reactive.lifetime.ended)
            .startWithValues({ [weak self] _ in
                let app = UIApplication.shared

                app.registerForNotificationsProducer(analytics).startWithCompleted({ [weak self] in
                    // if alerts were not enabled, tell the user that they must be
                    guard let strong = self else { return }
                    guard app.currentUserNotificationSettings?.types.contains(.alert) == false else { return }

                    // reset the preference
                    preferences.batteryAlertsEnabled.value = false

                    let bundle = Bundle.main
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Ringly"

                    AlertViewController(
                        openSettingsText: tr(.settingsEnableAlerts),
                        openSettingsDetailText: tr(.settingsEnableBatteryAlertsPrompt(name))
                    ).present(above: strong)
                })
            })
    }
}
