import ReactiveSwift

public extension Sequence
{
    // MARK: - Predicate Matching

    /**
     Returns `true` if `predicate` returns `true` for any element of `self`.

     - parameter predicate: The predicate function.
     */
    
    public func any(_ predicate: (Iterator.Element) -> Bool) -> Bool
    {
        for element in self
        {
            if predicate(element)
            {
                return true
            }
        }
        
        return false
    }

    /**
     Returns `true` if `predicate` returns `true` for all elements of `self`.

     - parameter predicate: The predicate function.
     */
    
    public func all(_ predicate: (Iterator.Element) -> Bool) -> Bool
    {
        for element in self
        {
            if !predicate(element)
            {
                return false
            }
        }

        return true
    }
}

extension Sequence
{
    // MARK: - Splitting

    /**
     Subdivides an array into two arrays.

     - parameter rightPredicate: If `true` is returned for a given element, it will be added to the second (right)
                                 array. Otherwise, it will be added to the first (left) array.
     */
    
    public func subdivide(_ rightPredicate: (Iterator.Element) -> Bool)
        -> ([Iterator.Element], [Iterator.Element])
    {
        var left: [Iterator.Element] = []
        var right: [Iterator.Element] = []

        for element in self
        {
            if rightPredicate(element)
            {
                right.append(element)
            }
            else
            {
                left.append(element)
            }
        }

        return (left, right)
    }
}

extension Sequence
{
    // MARK: - Dictionary Mapping

    /**
     Returns a dictionary of `[transform(V): V]` for each `V` in `self`.

     - parameter transform: A transformation function.
     */
    
    public func mapDictionaryKeys<K: Hashable>(_ transform: (Iterator.Element) -> K) -> [K:Iterator.Element]
    {
        return mapToDictionary({ element in (transform(element), element) })
    }

    /**
     Maps the sequence to a dictionary.

     - parameter transform: A transformation function, returning a tuple of `(Key, Value)`.
     */
    
    public func mapToDictionary<K: Hashable, V>(_ transform: (Iterator.Element) -> (K, V)) -> [K:V]
    {
        var dictionary = [K:V]()

        for element in self
        {
            let transformed = transform(element)
            dictionary[transformed.0] = transformed.1
        }

        return dictionary
    }
}

extension Sequence where Iterator.Element: Hashable
{
    /**
     Returns a dictionary of `[V: transform(V)]` for each `V` in `self`.

     - parameter transform: A transformation function.
     */
    
    public func mapDictionaryValues<V>(_ transform: (Iterator.Element) -> V) -> [Iterator.Element:V]
    {
        return mapToDictionary({ element in (element, transform(element)) })
    }
}

extension Sequence
{
    // MARK: - Deduplication

    /**
     Deduplicates the sequence, returning an array of the results.

     - parameter transform: A function to transform each value into a unique hashable value.
     */
    
    public func deduplicateWithKeyFunction<K: Hashable>(_ transform: (Iterator.Element) -> K)
        -> [Iterator.Element]
    {
        typealias Element = Iterator.Element // required to appease compiler

        var result = [Element]()
        var set = Set<K>()
        
        for element in self
        {
            let key = transform(element)
            
            if !set.contains(key)
            {
                set.insert(key)
                result.append(element)
            }
        }
        
        return result
    }
}

extension Sequence where Iterator.Element: OptionalProtocol
{
    public var unwrapped: [Iterator.Element.Wrapped]?
    {
        let initial = Optional.some(Array<Iterator.Element.Wrapped>())

        return reduce(initial, { current, next in
            current.flatMap({ array in
                next.optional.map({ array + [$0] })
            })
        })
    }
}

extension Sequence
{
    // MARK: - Repeating

    /**
     Repeats the sequence `times` times.

     - parameter times: The number of times to repeat the sequence.
     */
    
    public func repeated(times: Int) -> [Iterator.Element]
    {
        return (0..<times).flatMap({ _ in self })
    }
}
