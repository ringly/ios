import RinglyKit

extension DefaultColor: CustomStringConvertible
{
    public var description: String
    {
        return DefaultColorToString(self)
    }
}

extension RLYPeripheralFeatureSupport: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .supported:
            return "Supported"
        case .undetermined:
            return "Undetermined"
        case .unsupported:
            return "Unsupported"
        }
    }
}

extension RLYPeripheralValidationState: CustomStringConvertible
{
    public var description: String { return RLYPeripheralValidationStateToString(self) }
}

extension RLYVibration: CustomStringConvertible
{
    public var description: String
    {
        return RLYVibrationToString(self)
    }
}
