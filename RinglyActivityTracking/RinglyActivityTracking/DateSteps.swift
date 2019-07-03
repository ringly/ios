import Foundation

public struct DateSteps: Equatable
{
    // MARK: - Initialization
    public init(components: DateComponents, steps: Steps)
    {
        self.components = components
        self.steps = steps
    }

    // MARK: - Properties
    public let components: DateComponents
    public let steps: Steps
}

public func ==(lhs: DateSteps, rhs: DateSteps) -> Bool
{
    return lhs.components == rhs.components && lhs.steps == rhs.steps
}
