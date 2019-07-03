import ReactiveSwift
import UIKit
import enum Result.NoError

protocol SwitchProtocol: class
{
    var isOn: Bool { get }
    func setOn(_ on: Bool, animated: Bool)
    var valueChangedSignal: Signal<(), NoError> { get }
    var touchedSignal: Signal<(), NoError> { get }
}

extension UISwitch: SwitchProtocol
{
    var valueChangedSignal: Signal<(), NoError>
    {
        return reactive.controlEvents(.valueChanged).void
    }

    var touchedSignal: Signal<(), NoError>
    {
        return reactive.controlEvents(.touchUpInside).void
    }
}

extension SwitchProtocol
{
    func bindProducer(preferencesSwitch: PreferencesSwitch, to preferences: Preferences)
        -> SignalProducer<(), NoError>
    {
        let property = preferencesSwitch.property(in: preferences)
        let propertyBacking = preferencesSwitch.propertyBacking(in: preferences)

        return SignalProducer.`defer` { [weak self] in
            guard let strong = self else { return SignalProducer.empty }

            // initialize the switch with the current preference value
            strong.setOn(property.value, animated: false)

            // this isn't thread safe, but all of the actions need to take place on the main thread anyways
            var setting = false

            return SignalProducer.merge(
                SignalProducer(strong.valueChangedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }

                    setting = true
                    property.value = strong.isOn
                    setting = false
                }).ignoreValues(),
                property.producer.skip(first: 1).on(value: { [weak self] value in
                    guard let strong = self else { return }

                    if !setting
                    {
                        strong.setOn(value, animated: true)
                    }
                }).ignoreValues(),
                // only update backing if notifications enabled and user manually updates
                SignalProducer(strong.touchedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }
                    if preferences.notificationsEnabled.value { propertyBacking.value = strong.isOn }
                }).ignoreValues()
            )
        }
    }
    
    func bindProducer(mindfulSwitch: MindfulSwitch, to preferences: Preferences)
        -> SignalProducer<(), NoError>
    {
        let property = mindfulSwitch.property(in: preferences)
        let propertyBacking = mindfulSwitch.propertyBacking(in: preferences)
        
        return SignalProducer.`defer` { [weak self] in
            guard let strong = self else { return SignalProducer.empty }
            
            // initialize the switch with the current preference value
            strong.setOn(property.value, animated: false)
            
            // this isn't thread safe, but all of the actions need to take place on the main thread anyways
            var setting = false
            
            return SignalProducer.merge(
                SignalProducer(strong.valueChangedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }
                    
                    setting = true
                    property.value = strong.isOn
                    setting = false
                }).ignoreValues(),
                property.producer.skip(first: 1).on(value: { [weak self] value in
                    guard let strong = self else { return }
                    
                    if !setting
                    {
                        strong.setOn(value, animated: true)
                    }
                }).ignoreValues(),
                SignalProducer(strong.touchedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }
                    if preferences.notificationsEnabled.value { propertyBacking.value = strong.isOn }
                }).ignoreValues()
            )
        }
    }
    
    func bindProducer(activitySwitch: ActivitySwitch, to preferences: Preferences)
        -> SignalProducer<(), NoError>
    {
        let property = activitySwitch.property(in: preferences)
        let propertyBacking = activitySwitch.propertyBacking(in: preferences)

        return SignalProducer.`defer` { [weak self] in
            guard let strong = self else { return SignalProducer.empty }
            
            // initialize the switch with the current preference value
            strong.setOn(property.value, animated: false)
            
            // this isn't thread safe, but all of the actions need to take place on the main thread anyways
            var setting = false
            
            return SignalProducer.merge(
                SignalProducer(strong.valueChangedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }
                    
                    setting = true
                    property.value = strong.isOn
                    setting = false
                }).ignoreValues(),
                property.producer.skip(first: 1).on(value: { [weak self] value in
                    guard let strong = self else { return }
                    
                    if !setting
                    {
                        strong.setOn(value, animated: true)
                    }
                }).ignoreValues(),
                SignalProducer(strong.touchedSignal).on(value: { [weak self] _ in
                    guard let strong = self else { return }
                    if preferences.notificationsEnabled.value { propertyBacking.value = strong.isOn }
                }).ignoreValues()
            )
        }
    }
}
