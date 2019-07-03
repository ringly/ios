import RinglyAPI

extension InitializableOptionalType where Wrapped: Coding, Wrapped.Encoded == [String:Any]
{
    static func decode(any: Any?) throws -> Self
    {
        if let encoded = any as? [String:AnyObject]
        {
            return try decode(encoded)
        }
        else
        {
            throw DecodeAnyError()
        }
    }

    static func decode(_ encoded: [String:Any]) throws -> Self
    {
        if encoded["none"] as? Bool == true
        {
            return self.init(optional: nil)
        }
        else if let inner = encoded["some"] as? Wrapped.Encoded
        {
            return try self.init(optional: Wrapped.decode(inner))
        }
        else
        {
            throw DecodeError.key("some", from: encoded)
        }
    }

    var encoded: [String:Any]
    {
        switch optional
        {
        case .none:
            return ["none": true]
        case let .some(value):
            return ["some": value.encoded]
        }
    }
}
