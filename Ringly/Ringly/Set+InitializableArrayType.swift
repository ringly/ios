extension Set: InitializableArrayType
{
    var array: Array<Element>
    {
        return Array(self)
    }
}
