//
//  ANCSV2ServiceChange.swift
//  Ringly
//
//  Created by Nate Stedman on 10/14/15.
//  Copyright © 2015 Ringly. All rights reserved.
//

import Dwifft
import ReactiveCocoa

enum ANCSV2ServiceChange<T: Equatable>
{
    case Add(T)
    case Delete(T)
    
    /// Returns the value wrapped by the change.
    var value: T
    {
        switch self
        {
            case .Add(let value): return value
            case .Delete(let value): return value
        }
    }
    
    /// Returns true if the change is an "add" event.
    var isAdd: Bool
    {
        switch self
        {
            case .Add: return true
            case .Delete: return false
        }
    }
}

extension ANCSV2ServiceChange
{
    /**
    Creates an array of changes by comparing two arrays.
    
    - parameter previous: The previous array.
    - parameter current:  The current array.
    */
    static func fromArrays(previous: [T], current: [T]) -> [ANCSV2ServiceChange<T>]
    {
        return previous.diff(current).map({ result -> ANCSV2ServiceChange<T> in
            switch result
            {
            case .Delete(let index):
                return .Delete(previous[index])
            case .Insert(let index):
                return .Add(current[index])
            }
        })
    }
    
    /**
    Removes redundant changes in an array of changes.
    
    Adds are preferred over deletes (an add with a matching delete is actually an "update"), so the deletes are dropped.
    
    - parameter changes:     An array of changes.
    - parameter keyFunction: A function that transforms a change's value into a unique key, which will be used to
                             determine which changes are duplicates.
    */
    static func removeRedundant<K: Hashable>
        (changes: [ANCSV2ServiceChange<T>], keyFunction: T -> K) -> [ANCSV2ServiceChange<T>]
    {
        var set = Set<K>()
        var output = [ANCSV2ServiceChange<T>]()
        
        let addValues = { (values: [ANCSV2ServiceChange<T>]) in
            for value in values
            {
                let key = keyFunction(value.value)
                
                if !set.contains(key)
                {
                    output.append(value)
                    set.insert(key)
                }
            }
        }
        
        // add "add" commands first, so that redundant deletes are discarded
        addValues(changes.filter({ change in change.isAdd }))
        addValues(changes.filter({ change in !change.isAdd }))
        
        return output
    }
    
    /**
    Returns a deduplicated array of changes for as the provided signal producer sends values.
    
    - parameter producer:    The signal producer to use.
    - parameter keyFunction: A function that transforms a change's value into a unique key, which will be used to
                             determine which changes are duplicates.
    */
    static func forProducer<P: SignalProducerType, K: Hashable where P.Value == [T]>
        (producer: P, keyFunction: T -> K) -> SignalProducer<[ANCSV2ServiceChange<T>], P.Error>
    {
        return producer
            // combine with previous to calculate changes, don't calculate with the initial empty array
            .combinePrevious([])
            .skip(1)
            
            // calculate changes
            .map(ANCSV2ServiceChange.fromArrays)
            .map({ changes in
                ANCSV2ServiceChange.removeRedundant(changes, keyFunction: keyFunction)
            })
    }
}
