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
public typealias Wedge = (tailAngle: CGFloat, headAngle: CGFloat)

class TimeWedgeLayer: CAShapeLayer {
    
    open var isSelected = false
    open var showDeleteButton = true
    
    typealias Angle = CGFloat
    let fourPi =  CGFloat(4 * M_PI)
    
    var wedgeAngle: Wedge = Wedge(tailAngle: 0.7 * CGFloat(M_PI), headAngle: 0) {
        didSet {
            if (wedgeAngle.headAngle > fourPi  +  CGFloat(M_PI_2)){
                wedgeAngle.headAngle -= fourPi
            }
            if (wedgeAngle.headAngle <  CGFloat(M_PI_2) ){
                wedgeAngle.headAngle += fourPi
            }
            if (wedgeAngle.tailAngle  > wedgeAngle.headAngle + fourPi){
                wedgeAngle.tailAngle -= fourPi
            } else if (wedgeAngle.tailAngle  < wedgeAngle.headAngle ){
                wedgeAngle.tailAngle += fourPi
            }
        }
    }
    
    let twoPI =  CGFloat(2 * M_PI)
    var insetSize: CGSize = CGSize.zero
    var trackRadius: CGFloat = 100
    var buttonRadius: CGFloat = 44
    var pathWidth: CGFloat = 44
    var wedgeCenter: CGPoint = CGPoint.zero
    var wedgeTapTarget = UIBezierPath()
    
    var gradientColors = [UIColor.orange, UIColor.yellow]
    var gradientLocations: [CGFloat] = [0.0, 1.0]
    
    let wedgeLayer = CAShapeLayer()
    let tailLayer = TailKnobLayer()
    let headLayer = HeadKnobLayer()
    let wedgeWrapperLayer = CALayer()
    let deleteButtonLayer = CALayer()
    var radialGradientLayer = RadialGradientLayer()
    
    static let tailIdentifierName = "TailKnobIdentifier"
    static let headIdentifierName = "HeadKnobIdentifier"
    static let wedgeIdentifierName = "TimeWedgeIdentifier"
    static let deleteButtonIdentifierName = "DeleteButtonIdentifierName"
    
    init(headAngle: CGFloat, tailAngle: CGFloat, size: CGSize, wedgeCenter: CGPoint, insetSize: CGSize, pathWidth: CGFloat, trackRadius: CGFloat, buttonRadius: CGFloat, gradientColors: Array<UIColor>, gradientLocations: Array<CGFloat>) {
        super.init()
        self.bounds.size = size
        self.position = center
        self.wedgeWrapperLayer.bounds.size = size
        self.wedgeWrapperLayer.position = center
        self.radialGradientLayer.bounds.size = size
        self.radialGradientLayer.position = center
        
        self.wedgeAngle = Wedge(headAngle: headAngle, tailAngle: tailAngle)
        self.pathWidth = pathWidth
        self.insetSize = insetSize
        self.wedgeCenter = center
        self.trackRadius = trackRadius
        self.buttonRadius = buttonRadius
        self.gradientLocations = gradientLocations
        self.gradientColors = gradientColors
        tailLayer.name = TimeWedgeLayer.tailIdentifierName
        headLayer.name = TimeWedgeLayer.headIdentifierName
        wedgeLayer.name = TimeWedgeLayer.wedgeIdentifierName
        deleteButtonLayer.name = TimeWedgeLayer.deleteButtonIdentifierName
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
        
        
        
        self.addSublayer(wedgeWrapperLayer)
        
        wedgeWrapperLayer.addSublayer(wedgeLayer)
        
        let size = CGSize(width: 2 * buttonRadius, height: 2 * buttonRadius)
        //        let iSize = CGSize(width: 2 * iButtonRadius, height: 2 * iButtonRadius)
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: size)).cgPath
        
        tailLayer.path = circle
        headLayer.path = circle
        tailLayer.size = size
        headLayer.size = size
        
        tailLayer.fillColor = UIColor.green.cgColor
        headLayer.fillColor = UIColor.yellow.cgColor
        wedgeWrapperLayer.addSublayer(headLayer)
        wedgeWrapperLayer.addSublayer(tailLayer)
        
//        self.addSublayer(radialGradientLayer)
//        self.addSublayer(wedgeWrapperLayer)
        
        let deleteImage = UIImage(named: "crossIcon")?.cgImage
        deleteButtonLayer.size = size
        deleteButtonLayer.contents = deleteImage
        deleteButtonLayer.contentsGravity = kCAGravityCenter
        deleteButtonLayer.contentsScale = UIScreen.main.scale
        self.addSublayer(radialGradientLayer)
        
        self.addSublayer(deleteButtonLayer)
        
        
        self.updateRadialGradientLayer()
    }
    
    func updateRadialGradientLayer() {
        radialGradientLayer.mask = wedgeWrapperLayer
        radialGradientLayer.radius = wedgeWrapperLayer.frame.size.width/2.0
        radialGradientLayer.colors = gradientColors.map{$0.cgColor}
        radialGradientLayer.locations = gradientLocations
    }
    
    override func layoutSublayers() {
        wedgeWrapperLayer.occupation = (self.size, self.center)
        radialGradientLayer.occupation = (self.size, self.center)
        
        radialGradientLayer.radius = self.size.width/2.0
        
        wedgeLayer.occupation = (insetSize, wedgeCenter)
        wedgeLayer.lineWidth = pathWidth
        
        let color = UIColor.red
        if !isSelected {
//            color = color.withAlphaComponent(0.5)
            deleteButtonLayer.isHidden = true
        } else {
            if showDeleteButton {
                deleteButtonLayer.isHidden = false
            } else {
                deleteButtonLayer.isHidden = true
            }
        }
        
        wedgeLayer.strokeColor = color.cgColor
        wedgeLayer.fillColor = UIColor.clear.cgColor
        tailLayer.fillColor = color.cgColor
        headLayer.fillColor = color.cgColor
        
        let arcCenter = wedgeLayer.center
        wedgeLayer.path = UIBezierPath(
            arcCenter: arcCenter,
            radius: trackRadius,
            startAngle: ( twoPI  ) -  ((wedgeAngle.tailAngle - wedgeAngle.headAngle) >= twoPI ? wedgeAngle.tailAngle - twoPI : wedgeAngle.tailAngle),
            endAngle: ( twoPI ) -  wedgeAngle.headAngle,
            clockwise: true).cgPath
        tailLayer.position = proj(wedgeAngle.tailAngle)
        headLayer.position = proj(wedgeAngle.headAngle)
        
        let midPointAngle = (wedgeAngle.tailAngle + wedgeAngle.headAngle) / 2.0
        let midPoint = proj(midPointAngle)
        deleteButtonLayer.position = midPoint
        guard let wedgePath = wedgeLayer.path else {
            return
        }
        // Update the tap area for the wedge
        let wedgeBezierPath = UIBezierPath(cgPath: wedgeLayer.path!)
        
        let tapBezierPath = wedgePath.copy(strokingWithWidth: self.pathWidth, lineCap: wedgeBezierPath.lineCapStyle, lineJoin: wedgeBezierPath.lineJoinStyle, miterLimit: wedgeBezierPath.miterLimit)
        wedgeTapTarget = UIBezierPath(cgPath: tapBezierPath)
        
//        updateRadialGradientLayer()
    }
    
    override func hitTest(_ p: CGPoint) -> CALayer? {
        let headPoint = self.headLayer.convert(p, from: self.superlayer)
        let tailPoint = self.tailLayer.convert(p, from: self.superlayer)
        let wedgePoint = self.wedgeLayer.convert(p, from: self.superlayer)
        let deletePoint = self.deleteButtonLayer.convert(p, from: self.superlayer)
        
        if headLayer.path!.contains(headPoint, using: CGPathFillRule.evenOdd, transform: CGAffineTransform.identity) {
            return headLayer
        }
        else if (tailLayer.path!.contains(tailPoint, using: CGPathFillRule.evenOdd, transform: CGAffineTransform.identity)) {
            return tailLayer
        }
        else if !deleteButtonLayer.isHidden && deleteButtonLayer.contains(deletePoint) {
            return deleteButtonLayer
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
