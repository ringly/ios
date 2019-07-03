//
//  GuidedAudioIntroView.swift
//  Ringly
//
//  Created by Daniel Katz on 5/10/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class GuidedAudioIntroView: UIView {
    fileprivate let titleDescriptionView = UIView.newAutoLayout()
    fileprivate let titleLabel = UILabel.newAutoLayout()
    fileprivate let descriptionLabel = UILabel.newAutoLayout()
    fileprivate let authorStackView = UIStackView.newAutoLayout()
    fileprivate let timeLabel = UILabel.newAutoLayout()

    fileprivate let startSessionButton = UIButton.newAutoLayout()
    
    fileprivate let guidedAudioModel:MindfulnessExerciseModel
    
    var onComplete:(()->Void)?
    
    init(guidedAudioModel: MindfulnessExerciseModel) {
        self.guidedAudioModel = guidedAudioModel
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.alignment = .center
        self.addSubview(stackView)
        stackView.autoPinEdgeToSuperview(edge: .left, inset: 40)
        stackView.autoPinEdgeToSuperview(edge: .right, inset: 40)
        stackView.autoCenterInSuperview()
        
        titleLabel.attributedText = self.guidedAudioModel.title.uppercased().introAttributedString
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = self.guidedAudioModel.description?.introDescriptionAttributedString
        
        [titleLabel, descriptionLabel].forEach({ titleDescriptionView.addSubview($0) })
        titleLabel.autoPinEdgesToSuperviewEdges(excluding: .bottom)
        descriptionLabel.autoPin(edge: .top, to: .bottom, of: titleLabel, offset: 24)
        descriptionLabel.autoPinEdgesToSuperviewEdges(excluding: .top)
        
        //MARK: Start Button
        startSessionButton.layer.shadowOffset = CGSize.init(width: 0, height: 14)
        startSessionButton.layer.shadowRadius = 10
        startSessionButton.layer.shadowColor = UIColor.black.cgColor
        startSessionButton.layer.shadowOpacity = 0.1
        startSessionButton.setBackgroundImage(Asset.backgroundRing.image, for: .normal)
        startSessionButton.reactive.controlEvents(.touchUpInside)
            .observeValues({ [weak self] _ in
                self?.fadeOut {
                    self?.onComplete?()
                }
            })
        
        let iconImageView = UIImageView.init()
        iconImageView.pin_setImage(from: guidedAudioModel.image.rightValue, placeholderImage: guidedAudioModel.image.leftValue)
        iconImageView.contentMode = .scaleAspectFit
        startSessionButton.addSubview(iconImageView)
        iconImageView.autoAlign(axis: .horizontal, toSameAxisOf: startSessionButton, offset: -20    )
        iconImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        iconImageView.autoSetDimensions(to: CGSize.init(width: 69, height: 69))
        
        let iconLabelView = UILabel.newAutoLayout()
        iconLabelView.attributedText = "BEGIN".startBreathingTextAttributedString
        startSessionButton.addSubview(iconLabelView)
        iconLabelView.autoAlignAxis(toSuperviewAxis: .vertical)
        iconLabelView.autoAlign(axis: .horizontal, toSameAxisOf: startSessionButton, offset: 20)
        
        timeLabel.attributedText = guidedAudioModel.time.introSubAttributedString
        
        if let author = self.guidedAudioModel.author {
            authorStackView.axis = .horizontal
            authorStackView.spacing = 10
            let authorImageView = UIImageView.newAutoLayout()
            let authorNameLabel = UILabel.newAutoLayout()
            authorImageView.autoSetDimensions(to: CGSize.init(width: 32, height: 32))
            authorStackView.addArrangedSubview(authorImageView)
            authorStackView.addArrangedSubview(authorNameLabel)
            self.addSubview(authorStackView)
            authorStackView.autoPin(edge: .bottom, to: .bottom, of: self, offset: -34)
            authorStackView.autoAlign(axis: .vertical, toSameAxisOf: self)
            
            authorImageView.pin_setImage(from: author.image)
            authorNameLabel.attributedText = "Led by \(author.name)".introSubAttributedString
        }
        
        stackView.addArrangedSubview(titleDescriptionView)
        stackView.addArrangedSubview(startSessionButton)
        stackView.addArrangedSubview(timeLabel)
        
        startSessionButton.autoSetDimensions(to: CGSize.init(width: 150, height: 150))
    }
    
    func fadeOut(completion:@escaping (()->Void)) {
        let initialFadeOut = UIView.animationProducer(duration: 0.2) {
            self.titleLabel.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
            self.authorStackView.alpha = 0.0
            self.timeLabel.alpha = 0.0
        }
        
        let beginButtonFade = UIView.animationProducer(duration: 0.4) {
            self.startSessionButton.alpha = 0.0
            self.startSessionButton.transform = self.startSessionButton.transform.scaledBy(x: 1.4, y: 1.4)
        }
        
        SignalProducer.concat([
            initialFadeOut,
            beginButtonFade
            ]).startWithCompleted {
                completion()
        }
    }
}
