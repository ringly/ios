import UIKit

extension NSLayoutConstraint
{
    /**
     Activates and deactivates layout constraints based on boolean conditions.

     - parameter constraintsAndConditions: The array of constraints and conditions.
     */
    public static func conditionallyActivateConstraints(_ constraintsAndConditions: [(NSLayoutConstraint, Bool)])
    {
        // containers for enabling and disabling dynamic constraints
        let (disabledConstraints, enabledConstraints) = constraintsAndConditions.subdivide({ _, value in value })

        // enable and disable constraints
        disabledConstraints.forEach({ constraint, _ in constraint.isActive = false })
        enabledConstraints.forEach({ constraint, _ in constraint.isActive = true })
    }
}
