//
//  MindfulMinute.swift
//  RinglyActivityTracking
//
//  Created by Daniel Katz on 5/15/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import RealmSwift

public class MindfulnessSession: Object {
    dynamic public var id: String = NSUUID().uuidString
    dynamic var startTimestamp: Int32 = 0
    dynamic var minuteCount: Int32 = 0
    dynamic var mindfulnessType: MindfulnessType = .breathing
    dynamic var mindfulnessDescription: String = ""
    
    public convenience init(startTimestamp: Int32, minuteCount:Int32, type: MindfulnessType, description:String) {
        self.init()
        self.startTimestamp = startTimestamp
        self.minuteCount = minuteCount
        self.mindfulnessType = type
        self.mindfulnessDescription = description
    }
}

@objc public enum MindfulnessType: Int {
    case breathing
    case guidedAudio
    
    public var title:String {
        switch self {
        case .breathing:
            return "Breathing Exercises"
        case .guidedAudio:
            return "Guided Meditation"
        }
    }
}
