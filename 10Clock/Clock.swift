//
//  Clock.swift
//  SwiftClock
//
//  Created by Joseph Daniels on 01/09/16.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

@objc public  protocol TenClockDelegate {
    //Executed for every touch.
    @objc optional func timesUpdated(_ clock:TenClock, startDate:Date,  endDate:Date  ) -> ()
    //Executed after the user lifts their finger from the control.
    @objc optional func timesChanged(_ clock:TenClock, startDate:Date,  endDate:Date  ) -> ()
}
func medStepFunction(_ val: CGFloat, stepSize:CGFloat) -> CGFloat{
    let dStepSize = Double(stepSize)
    let dval  = Double(val)
    let nsf = floor(dval/dStepSize)
    let rest = dval - dStepSize * nsf
    return CGFloat(rest > dStepSize / 2 ? dStepSize * (nsf + 1) : dStepSize * nsf)

}

public enum ClockGradient: String {
    case linear = "linear"
    case radial = "radial"
}

public enum ClockHourType: Int {
    case twelveHour = 12
    case twentyFourHour = 24
}

public enum ClockInteractionType: String {
    case exact = "exact"
    case singleRange = "singleRange"
    case multiRange = "multiRange"
}

//XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
//@IBDesignable
@IBDesignable open class TenClock : UIControl {
    
    //MARK:- Public properties
    open var delegate:TenClockDelegate?
    
    open var startDate: Date{
        get{return angleToTime(tailAngle) }
        set{ tailAngle = timeToAngle(newValue) }
    }
    
    open var endDate: Date{
        get{return angleToTime(headAngle) }
        set{ headAngle = timeToAngle(newValue) }
    }
    
    open var clockInteractionType: ClockInteractionType = .exact
    
    open var gradientType: ClockGradient = .radial
    
    open var clockHourType: ClockHourType = .twelveHour {
        willSet {
            switch newValue {
            case .twelveHour:
                clockHourTypeHours = 12
            case .twentyFourHour:
                clockHourTypeHours = 24
            }
        }
    }
    open var pathWidth:CGFloat = 54
    var timeStepSize: CGFloat = 5
    var internalShift: CGFloat = 5
    
    open var shouldMoveHead = true
    open var shouldMoveTail = true
    
    
    open var numeralsColor:UIColor? = UIColor.darkGray
    open var minorTicksColor:UIColor? = UIColor.lightGray
    open var majorTicksColor:UIColor? = UIColor.blue
    open var centerTextColor:UIColor? = UIColor.darkGray
    
    open var titleColor = UIColor.lightGray
    open var titleGradientMask = false
    
    //disable scrol on closest superview for duration of a valid touch.
    var disableSuperviewScroll = false
    
    open var headBackgroundColor = UIColor.white.withAlphaComponent(0.8)
    open var tailBackgroundColor = UIColor.white.withAlphaComponent(0.8)
    
    open var headTextColor = UIColor.black
    open var tailTextColor = UIColor.black
    
    open var gradientColors = [UIColor.orange, UIColor.yellow]
    open var gradientLocations: [CGFloat] = [0.0, 1.0]
    
    open var minorTicksEnabled:Bool = true
    open var majorTicksEnabled:Bool = true
    @objc open var disabled:Bool = false {
        didSet{
            update()
        }
    }
    
    open var buttonInset:CGFloat = 2
    
    //overall inset. Controls all sizes.
    @IBInspectable var insetAmount: CGFloat = 40
    
    //MARK:- @IBInspectable Adapters
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'clockInteractionType' instead.")
    @IBInspectable var clockInteractionTypeName: String? {
        willSet {
            clockInteractionType = ClockInteractionType(rawValue: newValue ?? "exact")!
        }
    }
    
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'gradientType' instead.")
    @IBInspectable var clockGradientName: String? {
        willSet {
            gradientType = ClockGradient(rawValue: newValue ?? "linear")!
        }
    }
    
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'clockHourType' instead.")
    @IBInspectable var clockHourTypeName: String? {
        willSet {
            if newValue == "12" || newValue == "24" {
                clockHourType = ClockHourType(rawValue: Int(newValue!) ?? 12)!
            } else {
                clockHourType = .twelveHour
            }
        }
    }
    
    //MARK:- Constants
    let twoPi =  CGFloat(2 * M_PI)
    let fourPi =  CGFloat(4 * M_PI)
    
    //MARK:- Private properties
    let watchFaceDateFormatter : DateFormatter = {
        var df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df
    }()
    
    var clockHourTypeHours : Int = 12
    
    var headAngle: CGFloat = 0 {
        didSet{
            if (headAngle > fourPi  +  CGFloat(M_PI_2)){
                headAngle -= fourPi
            }
            if (headAngle <  CGFloat(M_PI_2) ){
                headAngle += fourPi
            }
        }
    }

    var tailAngle: CGFloat = 0.7 * CGFloat(M_PI) {
        didSet{
            if (tailAngle  > headAngle + fourPi){
                tailAngle -= fourPi
            } else if (tailAngle  < headAngle ){
                tailAngle += fourPi
            }

        }
    }
    
    var strokeColor: UIColor {
        get {
            return UIColor(cgColor: trackLayer.strokeColor!)
        }
        set(strokeColor) {
            trackLayer.strokeColor = strokeColor.cgColor
            pathLayer.strokeColor = strokeColor.cgColor
        }
    }
    
    func disabledFormattedColor(_ color:UIColor) -> UIColor{
        return disabled ? color.greyscale : color
    }

    var trackWidth:CGFloat {return pathWidth }
    
    func proj(_ theta:Angle) -> CGPoint{
        let center = self.layer.center
        return CGPoint(x: center.x + trackRadius * cos(theta) ,
                           y: center.y - trackRadius * sin(theta) )
    }

    var headPoint: CGPoint{
        return proj(headAngle)
    }
    var tailPoint: CGPoint{
        return proj(tailAngle)
    }

    lazy internal var calendar = Calendar(identifier:Calendar.Identifier.gregorian)
    
    func toDate(_ val:CGFloat)-> Date {
        return calendar.date(byAdding: Calendar.Component.minute , value: Int(val), to: Date().startOfDay as Date)!
    }

    var internalRadius:CGFloat {
        return internalInset.height
    }
    var inset:CGRect{
        return self.layer.bounds.insetBy(dx: insetAmount, dy: insetAmount)
    }
    var internalInset:CGRect{
        let reInsetAmount = trackWidth / 2 + internalShift
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var numeralInset:CGRect{
        let reInsetAmount = trackWidth / 2 + internalShift + internalShift
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var titleTextInset:CGRect{
        let reInsetAmount = trackWidth.checked / 2 + 4 * internalShift
        return (self.inset).insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var trackRadius:CGFloat { return inset.height / 2}
    var buttonRadius:CGFloat { return /*44*/ pathWidth / 2 }
    var iButtonRadius:CGFloat { return /*44*/ buttonRadius - buttonInset }
    
    //MARK:- Layers
    let gradientLayer = CAGradientLayer()
    let radialGradientLayer = RadialGradientLayer()
    let trackLayer = CAShapeLayer()
    let pathLayer = CAShapeLayer()
    let headLayer = CAShapeLayer()
    let tailLayer = CAShapeLayer()
    let topHeadLayer = CAShapeLayer()
    let topTailLayer = CAShapeLayer()
    let numeralsLayer = CALayer()
    var titleTextLayer = CATextLayer()
    let overallPathLayer = CALayer()
    
    let exactTitleTextLayer = CATextLayer()
    
    // The invisible trigger for user interaction
    let exactTimeIndicatorTouchLayer = CAShapeLayer()
    
    // The shape that is displayed
    let exactTimeIndicatorLayer = CAShapeLayer()
    
    let repLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = 48
        r.instanceTransform =
            CATransform3DMakeRotation(
                CGFloat(2*M_PI) / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()
    
    let repLayer2:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = 24
        r.instanceTransform =
            CATransform3DMakeRotation(
                CGFloat(2*M_PI) / CGFloat(r.instanceCount),
                0,0,1)
        
        return r
    }()

    //MARK:- Initialisation and setup
    override public init(frame: CGRect) {
        super.init(frame:frame)
        setup()
    }
    
    init(frame: CGRect, clockHourType: ClockHourType, gradientType: ClockGradient = .linear) {
        super.init(frame: frame)
        self.gradientType = gradientType
        self.clockHourType = clockHourType
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        // Check if we're drawing 12 hour or 24 hour clock
        self.clockHourTypeHours = self.clockHourType.rawValue
        
        backgroundColor = UIColor ( red: 0.1149, green: 0.115, blue: 0.1149, alpha: 0.0 )
        
        // Create the sublayers that make up the clock
        createSublayers()
        
        // Update all the layers
        update()
    }
    
    func createSublayers() {
        layer.addSublayer(repLayer2)
        layer.addSublayer(repLayer)
        layer.addSublayer(numeralsLayer)
        layer.addSublayer(trackLayer)
        
        switch self.gradientType {
        case .linear:
            layer.addSublayer(gradientLayer)
            gradientLayer.addSublayer(topHeadLayer)
            gradientLayer.addSublayer(topTailLayer)
        case .radial:
            layer.addSublayer(radialGradientLayer)
            radialGradientLayer.addSublayer(topHeadLayer)
            radialGradientLayer.addSublayer(topTailLayer)
        }
        
        switch self.clockInteractionType {
        case .exact:
            overallPathLayer.addSublayer(exactTimeIndicatorTouchLayer)
            overallPathLayer.addSublayer(titleTextLayer)
            layer.addSublayer(overallPathLayer)
            layer.addSublayer(exactTimeIndicatorLayer)
        default:
            overallPathLayer.addSublayer(pathLayer)
            overallPathLayer.addSublayer(headLayer)
            overallPathLayer.addSublayer(tailLayer)
            overallPathLayer.addSublayer(titleTextLayer)
            layer.addSublayer(overallPathLayer)
        }
        
        
        
        strokeColor = disabledFormattedColor(tintColor)
    }
    
    //MARK:- Update cycle
    open func update() {
        let mm = min(self.layer.bounds.size.height, self.layer.bounds.size.width)
        CATransaction.begin()
        self.layer.size = CGSize(width: mm, height: mm)

        strokeColor = disabledFormattedColor(tintColor)
        overallPathLayer.occupation = layer.occupation
        
        if self.gradientType == .linear {
            gradientLayer.occupation = layer.occupation
        } else {
            radialGradientLayer.occupation = layer.occupation
        }
        
        trackLayer.occupation = (inset.size, layer.center)

        pathLayer.occupation = (inset.size, overallPathLayer.center)
        repLayer.occupation = (internalInset.size, overallPathLayer.center)
        repLayer2.occupation  =  (internalInset.size, overallPathLayer.center)
        numeralsLayer.occupation = (numeralInset.size, layer.center)

        trackLayer.fillColor = UIColor.clear.cgColor
        pathLayer.fillColor = UIColor.clear.cgColor


        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        if self.gradientType == .linear {
            updateGradientLayer()
        } else {
            updateRadialGradientLayer()
        }
        updateTrackLayerPath()
        
        switch clockInteractionType {
        case .exact:
            updateSingleDialLayerPath()
        default:
            updatePathLayerPath()
            updateHeadTailLayers()
        }
        
        updateWatchFaceTicks()
        updateWatchFaceNumerals()
        updateWatchFaceTitle()
        CATransaction.commit()

    }
    
    func updateGradientLayer() {
        gradientLayer.colors = gradientColors.map(disabledFormattedColor).map{$0.cgColor}
        gradientLayer.mask = trackLayer
        gradientLayer.startPoint = CGPoint(x:0,y:0)
        gradientLayer.locations = gradientLocations as [NSNumber]?
    }
    
    func updateRadialGradientLayer() {
        radialGradientLayer.mask = trackLayer
        radialGradientLayer.radius = radialGradientLayer.size.width/2.0
        radialGradientLayer.colors = gradientColors.map(disabledFormattedColor).map{$0.cgColor}
        radialGradientLayer.locations = gradientLocations
    }

    func updateTrackLayerPath() {
        let circle = UIBezierPath(
            ovalIn: CGRect(
                origin:CGPoint(x: 0, y: 0),
                size: CGSize(width:trackLayer.size.width,
                    height: trackLayer.size.width)))
        trackLayer.lineWidth = pathWidth
        trackLayer.path = circle.cgPath

    }
    
    func updatePathLayerPath() {
        let arcCenter = pathLayer.center
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.lineWidth = pathWidth
        pathLayer.path = UIBezierPath(
            arcCenter: arcCenter,
            radius: trackRadius,
            startAngle: ( twoPi  ) -  ((tailAngle - headAngle) >= twoPi ? tailAngle - twoPi : tailAngle),
            endAngle: ( twoPi ) -  headAngle,
            clockwise: true).cgPath
    }


    func tlabel(_ str:String, color:UIColor? = nil) -> CATextLayer {
        let f = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        let cgFont = CTFontCreateWithName(f.fontName as CFString?, f.pointSize/2,nil)
        let l = CATextLayer()
        l.bounds.size = CGSize(width: 30, height: 15)
        l.fontSize = f.pointSize
        l.foregroundColor =  disabledFormattedColor(color ?? tintColor).cgColor
        l.alignmentMode = kCAAlignmentCenter
        l.contentsScale = UIScreen.main.scale
        l.font = cgFont
        l.string = str

        return l
    }
    
    func updateHeadTailLayers() {
        let size = CGSize(width: 2 * buttonRadius, height: 2 * buttonRadius)
        let iSize = CGSize(width: 2 * iButtonRadius, height: 2 * iButtonRadius)
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: size)).cgPath
        let iCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: iSize)).cgPath
        tailLayer.path = circle
        headLayer.path = circle
        tailLayer.size = size
        headLayer.size = size
        tailLayer.position = tailPoint
        headLayer.position = headPoint
        topTailLayer.position = tailPoint
        topHeadLayer.position = headPoint
        headLayer.fillColor = UIColor.yellow.cgColor
        tailLayer.fillColor = UIColor.green.cgColor
        topTailLayer.path = iCircle
        topHeadLayer.path = iCircle
        topTailLayer.size = iSize
        topHeadLayer.size = iSize
        topHeadLayer.fillColor = disabledFormattedColor(headBackgroundColor).cgColor
        topTailLayer.fillColor = disabledFormattedColor(tailBackgroundColor).cgColor
        topHeadLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        topTailLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let stText = tlabel("Sleep", color: disabledFormattedColor(headTextColor))
        let endText = tlabel("Wake",color: disabledFormattedColor(tailTextColor))
        stText.position = topTailLayer.center
        endText.position = topHeadLayer.center
        topHeadLayer.addSublayer(endText)
        topTailLayer.addSublayer(stText)
    }
    
    func updateSingleDialLayerPath() {
        let size = CGSize(width: 2 * buttonRadius, height: 2 * buttonRadius)
        let iSize = CGSize(width: 2 * iButtonRadius, height: 2 * iButtonRadius)
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: size)).cgPath
        let iCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: iSize)).cgPath
        
        exactTimeIndicatorTouchLayer.path = circle
        exactTimeIndicatorLayer.path = iCircle
        
        exactTimeIndicatorTouchLayer.size = size
        exactTimeIndicatorLayer.size = iSize
        
        exactTimeIndicatorTouchLayer.position = headPoint
        exactTimeIndicatorLayer.position = headPoint
        
        exactTimeIndicatorTouchLayer.fillColor = UIColor.yellow.cgColor
        exactTimeIndicatorLayer.fillColor = UIColor.red.cgColor
    }


    func updateWatchFaceNumerals() {
        numeralsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let f = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
        let cgFont = CTFontCreateWithName(f.fontName as CFString?, f.pointSize/2,nil)
        let startPos = CGPoint(x: numeralsLayer.bounds.midX, y: 15)
        let origin = numeralsLayer.center
        let step = (2 * M_PI) / Double(clockHourTypeHours)
        for i in (1 ... clockHourTypeHours){
            let l = CATextLayer()
            l.bounds.size = CGSize(width: i > 9 ? 18 : 8, height: 15)
            l.fontSize = f.pointSize
            l.alignmentMode = kCAAlignmentCenter
            l.contentsScale = UIScreen.main.scale
            //            l.foregroundColor
            l.font = cgFont
            l.string = "\(i)"
            l.foregroundColor = disabledFormattedColor(numeralsColor ?? tintColor).cgColor
            l.position = CGVector(from:origin, to:startPos).rotate( CGFloat(Double(i) * step)).add(origin.vector).point.checked
            numeralsLayer.addSublayer(l)
        }
    }
    
    func updateWatchFaceTitle() {
        
        let titleFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        let cgFont = CTFontCreateWithName(titleFont.fontName as CFString?, titleFont.pointSize/2,nil)
        titleTextLayer.fontSize = titleFont.pointSize
        titleTextLayer.alignmentMode = kCAAlignmentCenter
        titleTextLayer.foregroundColor = disabledFormattedColor(centerTextColor ?? tintColor).cgColor
        titleTextLayer.contentsScale = UIScreen.main.scale
        titleTextLayer.font = cgFont
        
        var titleString: String;
        switch clockInteractionType {
        case .exact:
             titleString = "\(watchFaceDateFormatter.string(from: endDate))"
        default:
            titleString = "\(watchFaceDateFormatter.string(from: startDate))\n↓\n\(watchFaceDateFormatter.string(from: endDate))"
        }
        
        let titleRect = (titleString as NSString).boundingRect(with: titleTextInset.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: titleFont], context: nil)
        titleTextLayer.string = titleString
        titleTextLayer.bounds.size = titleRect.size
        titleTextLayer.position = layer.center

    }
    
    func tick() -> CAShapeLayer{
        let tick = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0,y: -3))
        path.addLine(to: CGPoint(x: 0,y: 3))
        tick.path  = path.cgPath
        tick.bounds.size = CGSize(width: 6, height: 6)
        return tick
    }

    func updateWatchFaceTicks() {
        repLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let t = tick()
        t.strokeColor = disabledFormattedColor(minorTicksColor ?? tintColor).cgColor
        t.position = CGPoint(x: repLayer.bounds.midX, y: 10)
        repLayer.addSublayer(t)
        repLayer.position = self.bounds.center
        repLayer.bounds.size = self.internalInset.size

        repLayer2.sublayers?.forEach({$0.removeFromSuperlayer()})
        let t2 = tick()
        t2.strokeColor = disabledFormattedColor(majorTicksColor ?? tintColor).cgColor
        t2.lineWidth = 2
        t2.position = CGPoint(x: repLayer2.bounds.midX, y: 10)
        repLayer2.addSublayer(t2)
        repLayer2.position = self.bounds.center
        repLayer2.bounds.size = self.internalInset.size
    }

    //MARK:- Touch interaction
    var pointMover:((CGPoint) ->())?
    
//    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return super.hitTest(point, with: event)
//    }
    
//    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        return true
//    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let _ = self.trackLayer.hitTest( point ) else {
            return nil
        }
        if let _ = self.titleTextLayer.hitTest( point ) {
            return nil
        } else {
            return self
        }
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !disabled  else {
        		pointMover = nil
            return
        }
        
        let touch = touches.first!
        let pointOfTouch = touch.location(in: self)
        guard let layer = self.overallPathLayer.hitTest( pointOfTouch ) else { return }
        
        var prev = pointOfTouch
        let pointerMoverProducer: (@escaping (CGPoint) -> Angle, @escaping (Angle)->()) -> (CGPoint) -> () = { g, s in
            return { p in
                let c = self.layer.center
                let computedP = CGPoint(x: p.x, y: self.layer.bounds.height - p.y)
                let v1 = CGVector(from: c, to: computedP)
                let v2 = CGVector(angle:g( p ))

                s(clockDescretization(CGVector.signedTheta(v1, vec2: v2)))
                self.update()
            }

        }

        switch(layer){
        case exactTimeIndicatorTouchLayer:
            if (shouldMoveHead) {
                pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
            } else {
                pointMover = nil
            }
        case headLayer:
            if (shouldMoveHead) {
                pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
            } else {
                pointMover = nil
            }
        case tailLayer:
            if (shouldMoveHead) {
                pointMover = pointerMoverProducer({_ in self.tailAngle}, {self.headAngle += 0;self.tailAngle += $0})
            } else {
                    pointMover = nil
            }
        case pathLayer:
            if (shouldMoveHead) {
            		pointMover = pointerMoverProducer({ pt in
                		let x = CGVector(from: self.bounds.center,
                		                 to:CGPoint(x: prev.x, y: self.layer.bounds.height - prev.y)).theta;
                    prev = pt;
                    return x
                    }, {self.headAngle += $0; self.tailAngle += $0 })
            } else {
                    pointMover = nil
            }
        default: break
        }

        super.touchesBegan(touches, with: event)

    }
    
    override open  func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pointMover = nil
        delegate?.timesChanged?(self, startDate: self.startDate, endDate: endDate)
        super.touchesEnded(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let pointMover = pointMover else { return }
        pointMover(touch.location(in: self))
    	delegate?.timesUpdated?(self, startDate: self.startDate, endDate: endDate)
        super.touchesMoved(touches, with: event)
    }
    
    //MARK:- UIView overrides
    override open func layoutSubviews() {
        update()
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        // Clear all layers
        self.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        setup()
    }

    //MARK:- Helper functions
    // input a date, output: 0 to 4pi
    func timeToAngle(_ date: Date) -> Angle{
        let units : Set<Calendar.Component> = [.hour, .minute]
        let components = self.calendar.dateComponents(units, from: date)
        let min = Double(  60 * components.hour! + components.minute! )
        
        return medStepFunction(CGFloat(M_PI_2 - ( min / (Double(clockHourTypeHours) * 60)) * 2 * M_PI), stepSize: CGFloat( 2 * M_PI / (Double(clockHourTypeHours) * 60 / 5)))
    }
    
    // input an angle, output: Date
    func angleToTime(_ angle: Angle) -> Date{
        let dAngle = Double(angle)
        let min = CGFloat(((M_PI_2 - dAngle) / (2 * M_PI)) * (Double(clockHourTypeHours) * 60))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return self.calendar.date(byAdding: .minute, value: Int(medStepFunction(min, stepSize: 5/* minute steps*/)), to: startOfToday)!
    }
}
