//
//  TimeWedgeLayer.swift
//  TenClock
//
//  Created by Justyn Spooner on 09/01/2017.
//  Copyright © 2017 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

typealias HeadKnobLayer = CAShapeLayer
typealias TailKnobLayer = CAShapeLayer

class TimeWedgeLayer: CAShapeLayer {
    
    typealias Angle = CGFloat
    
    var tailAngle: CGFloat = 0
    var headAngle: CGFloat = 0.7 * CGFloat(M_PI)
    let twoPI =  CGFloat(2 * M_PI)
    var insetSize: CGSize = CGSize.zero
    var trackRadius: CGFloat = 100
    var buttonRadius: CGFloat = 44
    var pathWidth: CGFloat = 44
    var wedgeCenter: CGPoint = CGPoint.zero
    
    let wedgeLayer = CAShapeLayer()
    let tailLayer = TailKnobLayer()
    let headLayer = HeadKnobLayer()
    
    static let tailIdentifierName = "TailKnobIdentifier"
    static let headIdentifierName = "HeadKnobIdentifier"
    static let wedgeIdentifierName = "TimeWedgeIdentifier"
    
    init(headAngle: CGFloat, tailAngle: CGFloat, size: CGSize, wedgeCenter: CGPoint, insetSize: CGSize, pathWidth: CGFloat, trackRadius: CGFloat, buttonRadius: CGFloat) {
        super.init()
        self.bounds.size = size
        self.position = center
        self.headAngle = headAngle
        self.tailAngle = tailAngle
        self.pathWidth = pathWidth
        self.insetSize = insetSize
        self.wedgeCenter = center
        self.trackRadius = trackRadius
        self.buttonRadius = buttonRadius
        tailLayer.name = TimeWedgeLayer.tailIdentifierName
        headLayer.name = TimeWedgeLayer.headIdentifierName
        wedgeLayer.name = TimeWedgeLayer.wedgeIdentifierName
        setupLayer()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        setupLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLayer()
    }
    
    func setupLayer() {
        
        
        self.addSublayer(wedgeLayer)
        
        let size = CGSize(width: 2 * buttonRadius, height: 2 * buttonRadius)
        //        let iSize = CGSize(width: 2 * iButtonRadius, height: 2 * iButtonRadius)
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: size)).cgPath
        
        tailLayer.path = circle
        headLayer.path = circle
        tailLayer.size = size
        headLayer.size = size
        
        tailLayer.fillColor = UIColor.green.cgColor
        headLayer.fillColor = UIColor.yellow.cgColor
        self.addSublayer(headLayer)
        self.addSublayer(tailLayer)
        
    }
    
    override func layoutSublayers() {
        wedgeLayer.occupation = (insetSize, wedgeCenter)
        wedgeLayer.lineWidth = pathWidth
        wedgeLayer.strokeColor = UIColor.red.cgColor
        wedgeLayer.fillColor = UIColor.clear.cgColor
        let arcCenter = wedgeLayer.center
        wedgeLayer.path = UIBezierPath(
            arcCenter: arcCenter,
            radius: trackRadius,
            startAngle: ( twoPI  ) -  ((tailAngle - headAngle) >= twoPI ? tailAngle - twoPI : tailAngle),
            endAngle: ( twoPI ) -  headAngle,
            clockwise: true).cgPath
        tailLayer.position = proj(tailAngle)
        headLayer.position = proj(headAngle)
    }

//    override func contains(_ p: CGPoint) -> Bool {
//        if let path = wedgeLayer.path {
//            if path.contains(p) {
//                return true
//            }
//        }
//        if let path = tailLayer.path {
//            if path.contains(p) {
//                return true
//            }
//        }
//        if let path = headLayer.path {
//            if path.contains(p) {
//                return true
//            }
//        }
//        return false
//    }
    
    override func hitTest(_ p: CGPoint) -> CALayer? {
        
//        let transformTail = CGAffineTransform(translationX: -tailLayer.position.x, y: -tailLayer.position.y);
        
//        if let path = tailLayer.path {
//            if(path.contains(p)) {
//                // the touch is inside the shape
//                print("Tail hit")
//                return tailLayer
//            }
//        }
        
//        let transformWedge = CGAffineTransform(translationX: -wedgeLayer.position.x, y: -wedgeLayer.position.y);
        
//        if let path = wedgeLayer.path {
//            if(path.contains(p)) {
//                // the touch is inside the shape
//                print("Wedge hit")
//                return wedgeLayer
//            }
//        }
//        return nil
        
        if headLayer.hitTest(p) != nil {
            return headLayer
        }
        else if (tailLayer.hitTest(p) != nil) {
            return tailLayer
        }
        else if (wedgeLayer.hitTest(p) != nil) {
            return wedgeLayer
        }
        return nil
    }
    
    //MARK:- Helper functions
    func proj(_ theta:Angle) -> CGPoint{
        let center = self.center
        return CGPoint(x: center.x + trackRadius * cos(theta) ,
                       y: center.y - trackRadius * sin(theta) )
    }
}
