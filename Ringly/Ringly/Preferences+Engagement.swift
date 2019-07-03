import Foundation
import ReactiveSwift

extension Preferences
{
    /// A sub-structure of `Preferences` containing engagement properties.
    struct Engagement
    {
        /// Initializes a preferences engagement store.
        ///
        /// - Parameter backing: The backing store to use.
        init(backing: PreferencesBackingType)
        {
            self.addRemoveApplicationsState = MutableProperty(
                backing: backing,
                key: "engagement-addRemoveApplicationsState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )

            self.editApplicationBehaviorState = MutableProperty(
                backing: backing,
                key: "engagement-editApplicationBehaviorState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )

            self.setUpActivityState = MutableProperty(
                backing: backing,
                key: "engagement-setUpActivityState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )

            self.stayHydratedState = MutableProperty(
                backing: backing,
                key: "engagement-stayHydratedState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )

            self.stepGoalEncouragementState = MutableProperty(
                backing: backing,
                key: "engagement-stepGoalEncouragementState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.startedBreatherState = MutableProperty(
                backing: backing,
                key: "engagement-startedBreatherState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
            
            self.startedMeditationState = MutableProperty(
                backing: backing,
                key: "engagement-startedMeditationState",
                defaultValue: .unscheduled,
                makeBridge: PropertyListBridge.raw
            )
        }

        /// The state of the add/remove applications `EngagementNotification`.
        let addRemoveApplicationsState: MutableProperty<EngagementNotificationState>

        /// The state of the edit application behavior `EngagementNotification`.
        let editApplicationBehaviorState: MutableProperty<EngagementNotificationState>

        /// The state of the set up activity behavior `EngagementNotification`.
        let setUpActivityState: MutableProperty<EngagementNotificationState>

        /// The state of the stay hydrated `EngagementNotification`.
        let stayHydratedState: MutableProperty<EngagementNotificationState>

        /// The state of the step goal encouragement `EngagementNotification`.
        let stepGoalEncouragementState: MutableProperty<EngagementNotificationState>
        
        /// The state of starting breathing exercise `EngagementNotification`.
        let startedBreatherState: MutableProperty<EngagementNotificationState>
        
        /// The state of starting meditation program `EngagementNotification`.
        let startedMeditationState: MutableProperty<EngagementNotificationState>
    }
}
