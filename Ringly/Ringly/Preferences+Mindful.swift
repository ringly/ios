import Foundation
import ReactiveSwift

extension Preferences
{
    /// A sub-structure of `Preferences` containing mindful properties.
    struct Mindful
    {
        /// Initializes a preferences mindful store.
        ///
        /// - Parameter backing: The backing store to use.
        init(backing: PreferencesBackingType)
        {
            self.sundayState = MutableProperty(
                backing: backing,
                key: "mindful-sundayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.mondayState = MutableProperty(
                backing: backing,
                key: "mindful-mondayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.tuesdayState = MutableProperty(
                backing: backing,
                key: "mindful-tuesdayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.wednesdayState = MutableProperty(
                backing: backing,
                key: "mindful-wednesdayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.thursdayState = MutableProperty(
                backing: backing,
                key: "mindful-thursdayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.fridayState = MutableProperty(
                backing: backing,
                key: "mindful-fridayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.saturdayState = MutableProperty(
                backing: backing,
                key: "mindful-saturdayState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
        }
    
        /// The state of each day's 'MindfulNotification'
        let sundayState: MutableProperty<MindfulNotificationState>
        
        let mondayState: MutableProperty<MindfulNotificationState>
    
        let tuesdayState: MutableProperty<MindfulNotificationState>
        
        let wednesdayState: MutableProperty<MindfulNotificationState>
        
        let thursdayState: MutableProperty<MindfulNotificationState>
        
        let fridayState: MutableProperty<MindfulNotificationState>
        
        let saturdayState: MutableProperty<MindfulNotificationState>
    }
}
