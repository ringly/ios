//
//  MindfulMinuteDataSource.swift
//  RinglyActivityTracking
//
//  Created by Daniel Katz on 5/16/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

// MARK: - Data Source

/// A protocol for types providing data about the user's mindful minutes.
public protocol MindfulMinuteDataSource
{
    // MARK: - Mindful Minutes Data
    
    /**
     A producer for the mindful minutes data between the specified dates.
     
     - parameter startDate: The interval start date.
     - parameter endDate:   The interval end date.
     */
    func mindfulMinutesDataProducer(startDate: Date, endDate: Date)
        -> SignalProducer<MindfulMinuteData, NSError>
    
}

extension MindfulMinuteDataSource
{
    /**
     A producer for the mindful minutes data between the specified dates.
     
     - parameter startDate: The interval start date.
     - parameter endDate:   The interval end date.
     */
    func mindfulMinutesProducer(startDate: Date, endDate: Date)
        -> SignalProducer<MindfulMinute, NSError>
    {
        return mindfulMinutesDataProducer(startDate: startDate, endDate: endDate).map({ $0.minutes })
    }
}

/// A protocol for types that can provide mindful minutes.
public protocol MindfulMinuteData
{
    // Mindful minute count.
    var minuteCount: Int { get }
}

extension MindfulMinuteData
{
    public var minutes : MindfulMinute
    {
        return MindfulMinute(minuteCount: minuteCount)
    }
}

public struct MindfulMinute : MindfulMinuteData
{
    /// The number of mindful minutes in the data.
    public var minuteCount:Int
    
    /**
     Initializes a `Mindful Minutes` value.
     
     - parameter minuteCount: Mindful minutes performed.
     */
    public init(minuteCount: Int)
    {
    self.minuteCount = minuteCount
    }
    
    public static var zero: MindfulMinute { return MindfulMinute(minuteCount: 0) }
}

/**
 Adds two `MindfulMinute` values.
 
 - parameter lhs: The first `MindfulMinute` value.
 - parameter rhs: The second `MindfulMinute` value.
 
 - returns: A `Steps` value with the walking and running components of the two input `Steps` values added.
 */
public func +<L: MindfulMinuteData, R: MindfulMinuteData>(lhs: L, rhs: R) -> MindfulMinute
{
    return MindfulMinute(
        minuteCount: lhs.minuteCount + rhs.minuteCount
    )
}

public func ==<L: MindfulMinuteData, R: MindfulMinuteData>(lhs: L, rhs: R) -> Bool
{
    return lhs.minuteCount == rhs.minuteCount
}

extension MindfulMinute: Hashable
{
    public var hashValue: Int { return minuteCount }
}


/// An extension of `MindfulMinuteData` with a timestamp.
public protocol TimestampedMindfulMinuteData: MindfulMinuteData
{
    /// The timestamp for the mindful minute data.
    var timestamp: Int32 { get }
}
