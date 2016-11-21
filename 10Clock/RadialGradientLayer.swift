//
//  RadialGradientLayer.swift
//  TenClock
//
//  Created by Justyn Spooner on 21/11/2016.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

class RadialGradientLayer: CALayer {
    
    var radius:CGFloat = 20
    var gradientCenter: CGPoint = CGPoint(x: 0, y: 0)
    var colors:[CGColor] = [UIColor(red: 251/255, green: 237/255, blue: 33/255, alpha: 1.0).cgColor , UIColor(red: 251/255, green: 179/255, blue: 108/255, alpha: 1.0).cgColor]
    var locations:[CGFloat] = [0.0, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    override init() {
        super.init()
        self.gradientCenter = center
        needsDisplayOnBoundsChange = true
    }
    
    init(gradientCenter: CGPoint, radius: CGFloat, colors: [CGColor]) {
        super.init()
        self.gradientCenter = gradientCenter
        self.radius = radius
        self.colors = colors
        
        needsDisplayOnBoundsChange = true
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
    }
    
    override func draw(in ctx: CGContext) {
        
        ctx.saveGState()
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        
        ctx.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: radius, options: CGGradientDrawingOptions(rawValue: 0))
    }
    
}
