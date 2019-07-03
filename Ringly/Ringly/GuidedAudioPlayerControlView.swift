//
//  GuidedAudioPlayerView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/22/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation
import ReactiveSwift
import AudioPlayer

class GuidedAudioPlayerControlView: UIView {
    fileprivate let playButton = UIButton.newAutoLayout()
    fileprivate let pauseButton = UIButton.newAutoLayout()
    
    let playing = MutableProperty(false)
    let player: AudioPlayer
    let guidedAudioModel: MindfulnessExerciseModel
    
    
    init(guidedAudioModel: MindfulnessExerciseModel, player: AudioPlayer) {
        self.guidedAudioModel = guidedAudioModel
        self.player = player
        
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        playButton.setImage(Asset.audioPlay.image, for: .normal)
        playButton.reactive.isHidden <~ self.playing.producer
        playButton.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            self?.player.resume()
        })
        pauseButton.setImage(Asset.audioPause.image, for: .normal)
        pauseButton.reactive.isHidden <~ self.playing.producer.map({ !$0 })
        pauseButton.reactive.controlEvents(.touchUpInside).observeValues({ [weak self] _ in
            self?.player.pause()
        })
        
        self.addSubview(playButton)
        self.addSubview(pauseButton)
        playButton.autoSetDimensions(to: CGSize.init(width: 119, height: 119))
        pauseButton.autoSetDimensions(to: CGSize.init(width: 119, height: 119))
        playButton.autoCenterInSuperview()
        pauseButton.autoCenterInSuperview()
    }
}
