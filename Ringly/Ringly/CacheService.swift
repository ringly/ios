//
//  CacheService.swift
//  Ringly
//
//  Created by Daniel Katz on 5/23/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import RinglyAPI
import ReactiveSwift
import Result

class CacheService {
    let api:APIService
    
    init(api: APIService) {
        self.api = api        
    }
    
    var mindfulnessAudioSessions:[MindfulnessExerciseModel] = []
    
    func cacheGuidedAudioSessions(completion: (()-> Void)?) {
        let guidedMeditationRequest = GuidedMeditationsRequest.init()
        self.api.resultProducer(for: guidedMeditationRequest)
            .on(value: { guidedMediationResult in
                let guidedAudioModels = guidedMediationResult.meditations.map({ guidedMeditation -> MindfulnessExerciseModel in
                    let timeMinutesString = "\(guidedMeditation.lengthSeconds / 60) minutes"
                    return MindfulnessExerciseModel.init(
                        image: .right(guidedMeditation.iconUrl),
                        title: guidedMeditation.title,
                        subtitle: guidedMeditation.subtitle,
                        description: guidedMeditation.sessionDescription,
                        time: timeMinutesString,
                        timeInSeconds: TimeInterval(guidedMeditation.lengthSeconds),
                        assetUrl: guidedMeditation.audioFile,
                        author: guidedMeditation.author
                    )
                })
                self.mindfulnessAudioSessions = guidedAudioModels
            }).startWithCompleted {
                completion?()
        }
    }
}
