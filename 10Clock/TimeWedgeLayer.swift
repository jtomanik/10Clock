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
    var wedgeTapTarget = UIBezierPath()
    
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
        
        guard let wedgePath = wedgeLayer.path else {
            return
        }
        // Update the tap area for the wedge
        let wedgeBezierPath = UIBezierPath(cgPath: wedgeLayer.path!)
        
        let tapBezierPath = wedgePath.copy(strokingWithWidth: self.pathWidth, lineCap: wedgeBezierPath.lineCapStyle, lineJoin: wedgeBezierPath.lineJoinStyle, miterLimit: wedgeBezierPath.miterLimit)
        wedgeTapTarget = UIBezierPath(cgPath: tapBezierPath)
        
    }
    
    override func hitTest(_ p: CGPoint) -> CALayer? {
        let headPoint = self.headLayer.convert(p, from: self.superlayer)
        let tailPoint = self.tailLayer.convert(p, from: self.superlayer)
        let wedgePoint = self.wedgeLayer.convert(p, from: self.superlayer)
        
        if headLayer.path!.contains(headPoint, using: CGPathFillRule.evenOdd, transform: CGAffineTransform.identity) {
            return headLayer
        }
        else if (tailLayer.path!.contains(tailPoint, using: CGPathFillRule.evenOdd, transform: CGAffineTransform.identity)) {
            return tailLayer
        }
        else if (wedgeTapTarget.contains(wedgePoint)) {
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
