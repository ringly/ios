//
//  MindfulnessLandingTableViewCell.swift
//  Ringly
//
//  Created by Daniel Katz on 5/9/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit
import PINRemoteImage
import PINCache
import RinglyExtensions


class MindfulnessLandingTableViewCell: UITableViewCell {

    let exerciseIcon = UIImageView.newAutoLayout()
    let titleLabel = UILabel.newAutoLayout()
    let subtitleLabel = UILabel.newAutoLayout()
    let timeLabel = UILabel.newAutoLayout()

    // Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        self.selectionStyle = .none
        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)

        let bgView = UIView.newAutoLayout()
        bgView.backgroundColor = .white
        self.contentView.addSubview(bgView)
        bgView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8))
        
        exerciseIcon.contentMode = .scaleAspectFit
        bgView.addSubview(exerciseIcon)
        exerciseIcon.autoSetDimensions(to: CGSize.init(width: 69, height: 69))
        exerciseIcon.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 16, left: 16, bottom: 16, right: 0), excluding: .right)
        
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(timeLabel)

        bgView.addSubview(stackView)
        stackView.autoPin(edge: .left, to: .right, of: exerciseIcon, offset: 16)
        stackView.autoPinEdgesToSuperviewEdges(insets: UIEdgeInsets.init(top: 20, left: 0, bottom: 20, right: 16), excluding: .left)
    }
    
    func populate(model: MindfulnessExerciseModel) {
        self.exerciseIcon.pin_setImage(
            from: model.image.rightValue,
            placeholderImage: model.image.leftValue
        )
        
        let titleFontSize = DeviceScreenHeight.current.select(four: 13, five: 13, preferred: 16)
        
        self.titleLabel.attributedText = model.title.uppercased().attributes(color: UIColor.init(white: 0.2, alpha: 1.0), font: UIFont.gothamBook(CGFloat(titleFontSize)), paragraphStyle: nil, tracking: .controlsTracking).attributedString
        self.subtitleLabel.attributedText = model.subtitle.attributes(color: UIColor.init(white: 0.2, alpha: 0.7), font: UIFont.gothamBook(12), paragraphStyle: nil, tracking: 100.0).attributedString
        self.timeLabel.attributedText = model.time.attributes(color: UIColor.init(white: 0.2, alpha: 0.7), font: UIFont.gothamBook(12), paragraphStyle: nil, tracking: 100.0)
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
