protocol InitializableArrayType
{
    associatedtype Element
    init(_ array: Array<Element>)
    var array: Array<Element> { get }
}

extension Array: InitializableArrayType
{
    var array: Array<Element> { return self }
}
