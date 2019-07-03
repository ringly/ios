import RinglyActivityTracking
import RinglyAPI

extension Steps: Coding
{
    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: [String:Any]) throws -> Steps
    {
        return try Steps(
            walkingStepCount: encoded.decode("walking"),
            runningStepCount: encoded.decode("running")
        )
    }

    public var encoded: Encoded
    {
        return [
            "walking": walkingStepCount as AnyObject,
            "running": runningStepCount as AnyObject
        ]
    }
}

extension DateSteps: Coding
{
    public typealias Encoded = [String:Any]

    public static func decode(_ encoded: [String:Any]) throws -> DateSteps
    {
        return try DateSteps(
            components: DateComponents.decode(any: encoded["components"]),
            steps: Steps.decode(any: encoded["steps"])
        )
    }

    public var encoded: Encoded
    {
        return [
            "components": components.encoded,
            "steps": steps.encoded
        ]
    }
}
