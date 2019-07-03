//
//  PullState.swift
//  Ringly
//
//  Created by Daniel Katz on 5/2/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit

public enum PullState: Equatable {
    case none
    case pulling(pullProgress: Double, lastSync:Date?)
    case releaseToLoad(pullProgress: Double, lastSync:Date?)
    case loading
    case finished
    case error
    case countingError
}

public func ==(lhs: PullState, rhs: PullState) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.error, .error):
        return true
    case (.countingError, .countingError):
        return true
    case (.releaseToLoad, .releaseToLoad):
        return true
    case (.loading, .loading):
        return true
    case (.finished, .finished):
        return true
    case let (.pulling(lhsProgress, lhsLastSyncDate), .pulling(rhsProgress, rhsLastSyncDate)):
        return lhsProgress == rhsProgress && rhsLastSyncDate == lhsLastSyncDate
    default:
        return false
    }
}

