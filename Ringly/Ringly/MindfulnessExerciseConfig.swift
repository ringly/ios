//
//  MindfulnessExerciseConfig.swift
//  Ringly
//
//  Created by Daniel Katz on 5/10/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit

protocol MindfulnessExerciseConfig {
    var countdownSeconds:TimeInterval { get set }
    var totalTime:DispatchTimeInterval { get set }
}
