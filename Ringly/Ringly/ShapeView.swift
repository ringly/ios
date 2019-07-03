//
//  ShapeView.swift
//  Ringly
//
//  Created by Daniel Katz on 6/15/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import Foundation

class ShapeView: UIView
{
    var shapeMaker:((_ bounds:CGRect) -> CAShapeLayer)? {
        didSet {
            self.layer.addSublayer(shapeMaker!(bounds))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    static func downFacingCaret() -> ShapeView {
        let shapeView = ShapeView.init(frame: CGRect.init(x: 0, y: 0, width: 15, height: 8))
        
        shapeView.shapeMaker = { frame in
            let shape = CAShapeLayer.init()
            let bezierPath = UIBezierPath()
            bezierPath.move(to: CGPoint(x: 0, y: 0))
            bezierPath.addLine(to: CGPoint(x: frame.midX, y: frame.maxY))
            bezierPath.addLine(to: CGPoint(x: frame.maxX, y: 0))
            shape.strokeColor = UIColor.black.withAlphaComponent(0.25).cgColor
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 2
            shape.lineCap = "round"
            shape.lineJoin = "round"
            shape.path = bezierPath.cgPath
            
            shape.frame = frame
            
            return shape
        }
        
        return shapeView
    }
    
    static func tooltipBox(carotPosition: Double) -> ShapeView {
        let shapeView = ShapeView.init(frame: CGRect.init(x: 0, y: 0, width: 140, height: 70))
        let purpleColor = UIColor(red: 162/255.0, green: 93/255.0, blue: 140/255.0, alpha: 1.0).cgColor
        
        // base box for tooltip
        shapeView.shapeMaker = { frame in
            let shape = CAShapeLayer.init()
            let bezierPath = UIBezierPath()
            let frameMaxY = frame.maxY - 8

            bezierPath.move(to: CGPoint(x: frame.minX, y: frame.minY))
            bezierPath.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            bezierPath.addLine(to: CGPoint(x: frame.maxX, y: frameMaxY))
            bezierPath.addLine(to: CGPoint(x: frame.minX, y: frameMaxY))
            bezierPath.close()
            shape.strokeColor = purpleColor
            shape.fillColor = purpleColor
            shape.lineWidth = 2
            shape.lineCap = "butt"
            shape.lineJoin = "butt"
            shape.path = bezierPath.cgPath
            shape.frame = frame
            
            return shape
        }
        
        // only center carot for midday hours
        if carotPosition == 5.0 {
            shapeView.shapeMaker = { frame in
                let shape = CAShapeLayer.init()
                let bezierPath = UIBezierPath()
                let frameStartX = frame.maxX * CGFloat(carotPosition/10.0)
                let frameStartY = frame.maxY - 8

                bezierPath.move(to: CGPoint(x: frameStartX - 7, y: frameStartY))
                bezierPath.addLine(to: CGPoint(x: frameStartX, y: frame.maxY))
                bezierPath.addLine(to: CGPoint(x: frameStartX + 7, y: frameStartY))
                shape.strokeColor = purpleColor
                shape.fillColor = purpleColor
                shape.lineWidth = 2
                shape.lineCap = "round"
                shape.lineJoin = "round"
                shape.path = bezierPath.cgPath
                
                shape.frame = frame
                
                return shape
            }
        }
        // for early hours, align carot left, leave 5pt buffer at beginning
        else if carotPosition < 5.0 {
            shapeView.shapeMaker = { frame in
                let shape = CAShapeLayer.init()
                let bezierPath = UIBezierPath()
                let frameStartX = frame.maxX * CGFloat(carotPosition/10.0) + 5.0
                let frameStartY = frame.maxY - 8
                
                bezierPath.move(to: CGPoint(x: frameStartX, y: frameStartY))
                bezierPath.addLine(to: CGPoint(x: frameStartX + 7, y: frame.maxY))
                bezierPath.addLine(to: CGPoint(x: frameStartX + 14, y: frameStartY))
                shape.strokeColor = purpleColor
                shape.fillColor = purpleColor
                shape.lineWidth = 2
                shape.lineCap = "round"
                shape.lineJoin = "round"
                shape.path = bezierPath.cgPath
                
                shape.frame = frame
                
                return shape
            }
        }
        // for later hours, align carot right, leave 5pt buffer at end
        else {
            shapeView.shapeMaker = { frame in
                let shape = CAShapeLayer.init()
                let bezierPath = UIBezierPath()
                let frameStartX = frame.maxX * CGFloat(carotPosition/10.0) - 5.0
                let frameStartY = frame.maxY - 8
                
                bezierPath.move(to: CGPoint(x: frameStartX - 14, y: frameStartY))
                bezierPath.addLine(to: CGPoint(x: frameStartX - 7, y: frame.maxY))
                bezierPath.addLine(to: CGPoint(x: frameStartX, y: frameStartY))
                shape.strokeColor = purpleColor
                shape.fillColor = purpleColor
                shape.lineWidth = 2
                shape.lineCap = "round"
                shape.lineJoin = "round"
                shape.path = bezierPath.cgPath
                
                shape.frame = frame
                
                return shape
            }
        }
        
        return shapeView
    }
}
