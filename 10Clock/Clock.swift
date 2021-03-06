//
//  Clock.swift
//  SwiftClock
//
//  Created by Joseph Daniels on 01/09/16.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

public typealias RangedTime = (startTime: Date, endTime: Date)

public protocol TenClockDelegate: class {
    //Executed for every touch.
    func timesUpdated(_ clock:TenClock, startDate:Date,  endDate:Date  ) -> ()
    //Executed after the user lifts their finger from the control.
    func timesChanged(_ clock:TenClock, startDate:Date,  endDate:Date  ) -> ()
    //Executed for every touch.
    func rangedTimesUpdated(_ clock:TenClock, rangedTimes: Array<RangedTime>, selectedIndex: Int ) -> ()
    //Executed after the user lifts their finger from the control.
    func rangedTimesChanged(_ clock:TenClock, rangedTimes: Array<RangedTime>, selectedIndex: Int ) -> ()
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
    
    open var rangedTimes: Array<RangedTime> = [] {
        didSet {
            if oldValue.count != rangedTimes.count {
                // Update the ranged angles
                rangedAngles.removeAll()
                
                for rangedTime in rangedTimes {
                    let tailAngle = timeToAngle(rangedTime.startTime)
                    let headAngle = timeToAngle(rangedTime.endTime)
                    let wedgeAngle = Wedge(tailAngle: tailAngle, headAngle: headAngle)
                    rangedAngles.append(wedgeAngle)
                }
                self.resetTimeWedges()
            }
            self.update()
        }
    }
    
    internal var rangedAngles: Array<Wedge> = []
    
    open var clockInteractionType: ClockInteractionType = .exact {
        didSet {
            switch clockInteractionType {
            case .exact:
                minuteStep = 5
            case .singleRange, .multiRange:
                minuteStep = 30
            }
            self.setup()
        }
    }
    
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
    
    open var clockFaceFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
    open var clockNumeralsFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
    
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
    
    open var trackGradientColors = [UIColor.black, UIColor(red:200.0/255.0, green:200.0/255.0, blue:200.0/255.0, alpha:1.0)]
    open var trackGradientLocations: [CGFloat] = [0.0, 1.0]
    
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
    
    var minuteStep = 5
    
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
//    var tailPoint: CGPoint{
//        return proj(tailAngle)
//    }

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
    var internalRect:CGRect{
        let reInsetAmount = trackWidth / 2
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
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
    var gradientLayer = CAGradientLayer()
    var radialGradientLayer = RadialGradientLayer()
    var trackRadialGradientLayer = RadialGradientLayer()
    let trackLayer = CAShapeLayer()
    let pathLayer = CAShapeLayer()
//    let headLayer = CAShapeLayer()
//    let tailLayer = CAShapeLayer()
    var topHeadLayer = CAShapeLayer()
    var topTailLayer = CAShapeLayer()
    let numeralsLayer = CALayer()
    var startTimeTextLayer = CATextLayer()
    var endTimeTextLayer = CATextLayer()
    var downArrowImageLayer = CALayer()
    var overallPathLayer = CALayer()
    var centerBackgroundLayer = CAShapeLayer()
    
    // Container layer for ranged time segments
    var rangedSegmentsLayer = CALayer()
    
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
    
    var timeWedges: Array<TimeWedgeLayer> = []
    var selectedTimeWedgeIndex = 0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
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
        
        
//        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerDidFire(timer:)), userInfo: nil, repeats: true)
        
        // Clear all existing layers
        timeWedges = []
        
        self.gradientLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.gradientLayer = CAGradientLayer()
        self.radialGradientLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.radialGradientLayer = RadialGradientLayer()
        self.rangedSegmentsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        self.overallPathLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.overallPathLayer = CALayer()
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.topHeadLayer = CAShapeLayer()
        self.topTailLayer = CAShapeLayer()
        // Check if we're drawing 12 hour or 24 hour clock
        self.clockHourTypeHours = self.clockHourType.rawValue
        
        backgroundColor = UIColor ( red: 0.1149, green: 0.115, blue: 0.1149, alpha: 0.0 )
        
        // Create the sublayers that make up the clock
        createSublayers()
        
        // Update all the layers
        update()
    }
    
//    func timerDidFire(timer: Timer) {
//        if let endTime = (rangedTimes[1])["end"] {
//            (rangedTimes[1])["end"] = endTime.addingTimeInterval(60*60)
//            self.setNeedsLayout()
//        }
//    }
    
    func createSublayers() {
//        layer.addSublayer(repLayer2)
//        layer.addSublayer(repLayer)
        layer.addSublayer(centerBackgroundLayer)
        layer.addSublayer(numeralsLayer)
        layer.addSublayer(trackLayer)
        layer.addSublayer(trackRadialGradientLayer)
//        switch self.gradientType {
//        case .linear:
////            layer.addSublayer(gradientLayer)
////            gradientLayer.addSublayer(topHeadLayer)
////            gradientLayer.addSublayer(topTailLayer)
//        case .radial:
////            layer.addSublayer(radialGradientLayer)
////            radialGradientLayer.addSublayer(topHeadLayer)
////            radialGradientLayer.addSublayer(topTailLayer)
//        }
        
        switch self.clockInteractionType {
        case .exact:
            overallPathLayer.addSublayer(exactTimeIndicatorTouchLayer)
            layer.addSublayer(radialGradientLayer)
            layer.addSublayer(endTimeTextLayer)
            layer.addSublayer(overallPathLayer)
            layer.addSublayer(exactTimeIndicatorLayer)
        default:
            overallPathLayer.addSublayer(rangedSegmentsLayer)
            resetTimeWedges()
            layer.addSublayer(startTimeTextLayer)
            layer.addSublayer(endTimeTextLayer)
            layer.addSublayer(downArrowImageLayer)
            layer.addSublayer(overallPathLayer)
            // Load the down arrow for the multi range mode
            downArrowImageLayer.contents = UIImage(named: "downIcon")?.cgImage
            downArrowImageLayer.contentsGravity = kCAGravityCenter
            downArrowImageLayer.size = CGSize(width: 18.0, height: 18.0)
//            downArrowImageLayer.contentsScale = UIScreen.main.scale
        }
        
        // Update scale factor for all view
        self.layer.sublayers?.forEach({$0.contentsScale = UIScreen.main.scale})
        self.layer.applyChangeToAllSublayers{$0.contentsScale = UIScreen.main.scale}
        strokeColor = disabledFormattedColor(tintColor)
    }
    
    //MARK:- Update cycle
    open func update() {
        let mm = min(self.layer.bounds.size.height, self.layer.bounds.size.width)
        CATransaction.begin()
        self.layer.size = CGSize(width: mm, height: mm)
        
        strokeColor = disabledFormattedColor(tintColor)
        overallPathLayer.occupation = layer.occupation
        rangedSegmentsLayer.occupation = layer.occupation
        trackRadialGradientLayer.occupation = layer.occupation
        
        if self.gradientType == .linear {
            gradientLayer.occupation = layer.occupation
        } else {
            radialGradientLayer.occupation = layer.occupation
        }
        
        trackLayer.occupation = (inset.size, layer.center)
        
        pathLayer.occupation = (inset.size, overallPathLayer.center)
        
        repLayer.occupation = (internalInset.size, overallPathLayer.center)
        repLayer2.occupation  =  (internalInset.size, overallPathLayer.center)
        centerBackgroundLayer.occupation = (internalRect.size, overallPathLayer.center)
        numeralsLayer.occupation = (numeralInset.size, layer.center)
        downArrowImageLayer.position = layer.center
        
        trackLayer.fillColor = UIColor.clear.cgColor
        pathLayer.fillColor = UIColor.clear.cgColor
        
        updateCenterBackgroundLayer()
        updateWatchFaceTimeWedges()
        
        updateTrackRadialGradientLayer()
        
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        if self.gradientType == .linear {
//            updateGradientLayer()
        } else {
//            updateRadialGradientLayer()
        }
        updateTrackLayerPath()
        
        switch clockInteractionType {
        case .exact:
            updateRadialGradientLayer()
            updateSingleDialLayerPath()
        default:
            break
            //            updatePathLayerPath()
            //            updateHeadTailLayers()
        }
        
        //        updateWatchFaceTicks()
        updateWatchFaceNumerals()
        updateWatchFaceTitle()
        
        CATransaction.commit()
        
    }
    
    func resetTimeWedges() {
        self.rangedSegmentsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        timeWedges.removeAll()
        addTimeWedges()
    }
    
    func addTimeWedges() {
        for rangedAngle in rangedAngles {
            addTimeWedge(rangedAngle: rangedAngle)
        }
    }
    
    func addTimeRangeAtPoint(angle: Angle) {
        let tappedTime = angleToTime(angle)
        let newTime = tappedTime.nextHalfHour()
        var startTime = newTime.addHours(hoursToAdd: -2)
        var endTime = newTime.addHours(hoursToAdd: 2)
        
        // Make sure we're not straddling midnight
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        
        var requiresSnappingToMidnight = false
        if startComponents.hour == endComponents.hour {
            if startComponents.minute! >= endComponents.minute! {
                requiresSnappingToMidnight = true
            }
        } else if startComponents.hour! > endComponents.hour! {
            requiresSnappingToMidnight = true
        }
        
        if requiresSnappingToMidnight {
            // Check which side of midnight we should snap
            let tappedTimeComponents = calendar.dateComponents([.hour, .minute], from: tappedTime)
            if tappedTimeComponents.hour! > 12 {
                var dateComponents = DateComponents()
                dateComponents.hour = 23
                dateComponents.minute = 30
                endTime = calendar.date(from: dateComponents)!
                startTime = endTime.addHours(hoursToAdd: -3)
            } else {
                var dateComponents = DateComponents()
                dateComponents.hour = 0
                dateComponents.minute = 0
                startTime = calendar.date(from: dateComponents)!
                endTime = startTime.addHours(hoursToAdd: 3)
            }
        }
        
        
        // Check that these times don't overlap another one already
        rangedTimes.forEach { (rangedTime) in
            
            // If the next range's start overlaps this new times end then offset our end
            if rangedTime.startTime < endTime &&
                rangedTime.startTime > startTime {
                endTime = rangedTime.startTime.addHours(hoursToAdd: -1)
            }
            // If the previous range's end time overlaps this new times start then offset our start
            if rangedTime.endTime > startTime &&
                rangedTime.startTime < endTime {
                startTime = rangedTime.endTime.addHours(hoursToAdd: 1)
            }
            
            if startTime >= endTime || startTime.addHours(hoursToAdd: 1) >= endTime {
                // This segment doesn't have enough space to fit here
                return
            }
        }
        
        let rangedTime = RangedTime(startTime: startTime, endTime: endTime)
        rangedTimes.append(rangedTime)
        
        selectedTimeWedgeIndex = rangedTimes.count - 1
    
    }
    
    func addTimeWedge(rangedAngle: Wedge) {
        let wedgeLayer = TimeWedgeLayer(headAngle: rangedAngle.tailAngle,
                                        tailAngle: rangedAngle.headAngle,
                                        size: overallPathLayer.size,
                                        wedgeCenter: overallPathLayer.center,
                                        insetSize: inset.size,
                                        pathWidth: pathWidth,
                                        trackRadius: trackRadius,
                                        buttonRadius: buttonRadius,
                                        gradientColors: gradientColors,
                                        gradientLocations: gradientLocations)
        
        
        
        rangedSegmentsLayer.addSublayer(wedgeLayer)
        
        // Add the layer to an instance variable so we can manage removal
        timeWedges.append(wedgeLayer)
    }
    
    func removeTimeWedge(at index: Int) {
        if timeWedges.indices.contains(index) {
            (timeWedges[index] as TimeWedgeLayer).removeFromSuperlayer()
            timeWedges.remove(at: index)
        }
        if rangedAngles.indices.contains(index) {
            rangedAngles.remove(at: index)
        }
        if rangedTimes.indices.contains(index) {
            rangedTimes.remove(at: index)
        }
    }
    
    func updateTimesForWedges() {
        for (index, rangedAngle) in rangedAngles.enumerated() {
            let startTime = angleToTime(rangedAngle.tailAngle)
            let endTime = angleToTime(rangedAngle.headAngle)
            rangedTimes[index].startTime = startTime
            rangedTimes[index].endTime = endTime// = RangedTime(startTime: startTime, endTime: endTime)
        }
    }
    
    func updateCenterBackgroundLayer() {
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y: 0), size: self.centerBackgroundLayer.size))
        centerBackgroundLayer.path = circle.cgPath
        centerBackgroundLayer.fillColor = UIColor(red:0.890, green:0.965, blue:0.949, alpha:1).cgColor
    }
    
    func updateWatchFaceTimeWedges() {
        
        for (index, timeWedge) in timeWedges.enumerated() {
            
            let tailAngle = rangedAngles[index].tailAngle
            let headAngle = rangedAngles[index].headAngle
            
            timeWedge.occupation = overallPathLayer.occupation
            timeWedge.wedgeAngle = Wedge(headAngle: headAngle, tailAngle: tailAngle)
            timeWedge.size = overallPathLayer.size
            timeWedge.wedgeCenter = overallPathLayer.center
            timeWedge.insetSize = inset.size
            timeWedge.pathWidth = pathWidth
            timeWedge.trackRadius = trackRadius
            timeWedge.buttonRadius = buttonRadius
            
            if index == selectedTimeWedgeIndex {
                timeWedge.isSelected = true
                if timeWedges.count > 1 {
                    timeWedge.showDeleteButton = true
                } else {
                    timeWedge.showDeleteButton = false
                }
            } else {
                timeWedge.isSelected = false
                timeWedge.showDeleteButton = false
            }
            
            timeWedge.setNeedsLayout()
        }
    }
    
    func tlabel(_ str:String, color:UIColor? = nil) -> CATextLayer {
        let cgFont = CTFontCreateWithName(self.clockNumeralsFont.fontName as CFString?, self.clockNumeralsFont.pointSize/2,nil)
        let l = CATextLayer()
        l.bounds.size = CGSize(width: 30, height: 15)
        l.fontSize = self.clockNumeralsFont.pointSize
        l.foregroundColor =  disabledFormattedColor(color ?? tintColor).cgColor
        l.alignmentMode = kCAAlignmentCenter
        l.contentsScale = UIScreen.main.scale
        l.font = cgFont
        l.string = str
        
        return l
    }
    
    func updateGradientLayer() {
        gradientLayer.colors = gradientColors.map(disabledFormattedColor).map{$0.cgColor}
        gradientLayer.mask = overallPathLayer
        gradientLayer.startPoint = CGPoint(x:0,y:0)
        gradientLayer.locations = gradientLocations as [NSNumber]?
    }
    
    func updateRadialGradientLayer() {
        radialGradientLayer.mask = overallPathLayer
        radialGradientLayer.radius = radialGradientLayer.size.width/2.0
        radialGradientLayer.colors = gradientColors.map(disabledFormattedColor).map{$0.cgColor}
        radialGradientLayer.locations = gradientLocations
    }
    
    func updateTrackRadialGradientLayer() {
        trackRadialGradientLayer.mask = trackLayer
        trackRadialGradientLayer.radius = trackRadialGradientLayer.size.width/2.0
        trackRadialGradientLayer.colors = trackGradientColors.map(disabledFormattedColor).map{$0.cgColor}
        trackRadialGradientLayer.locations = trackGradientLocations
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
        
        exactTimeIndicatorLayer.fillColor = UIColor.clear.cgColor
    }


    func updateWatchFaceNumerals() {
        numeralsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let cgFont = CTFontCreateWithName(self.clockNumeralsFont.fontName as CFString?, self.clockNumeralsFont.pointSize/2,nil)
        let startPos = CGPoint(x: numeralsLayer.bounds.midX, y: 15)
        let origin = numeralsLayer.center
        let step = (2 * M_PI) / Double(clockHourTypeHours)
        for i in (1 ... clockHourTypeHours){
            if i%6 == 0 {
                let l = CATextLayer()
//                l.bounds.size = CGSize(width: i > 9 ? 18 : 8, height: 15)
                l.bounds.size = CGSize(width: 30, height: 15)
                l.fontSize = self.clockNumeralsFont.pointSize
                l.alignmentMode = kCAAlignmentCenter
                l.contentsScale = UIScreen.main.scale
                //            l.foregroundColor
                l.font = cgFont
                l.string = String(format: "%02d:00", i == 24 ? 0 : i)
//                l.string = "\(i):00"
                l.foregroundColor = disabledFormattedColor(numeralsColor ?? tintColor).cgColor
                l.position = CGVector(from:origin, to:startPos).rotate( CGFloat(Double(i) * step)).add(origin.vector).point.checked
                numeralsLayer.addSublayer(l)
            }
        }
    }
    
    func updateWatchFaceTitle() {
        
        let cgFont = CTFontCreateWithName(self.clockFaceFont.fontName as CFString?, self.clockFaceFont.pointSize/2,nil)
        startTimeTextLayer.fontSize = self.clockFaceFont.pointSize
        startTimeTextLayer.alignmentMode = kCAAlignmentCenter
        startTimeTextLayer.foregroundColor = disabledFormattedColor(centerTextColor ?? tintColor).cgColor
        startTimeTextLayer.contentsScale = UIScreen.main.scale
        startTimeTextLayer.font = cgFont
        
        endTimeTextLayer.fontSize = self.clockFaceFont.pointSize
        endTimeTextLayer.alignmentMode = kCAAlignmentCenter
        endTimeTextLayer.foregroundColor = disabledFormattedColor(centerTextColor ?? tintColor).cgColor
        endTimeTextLayer.contentsScale = UIScreen.main.scale
        endTimeTextLayer.font = cgFont
        
        var startTimeString = "\(watchFaceDateFormatter.string(from: startDate))"
        var endTimeString = "\(watchFaceDateFormatter.string(from: endDate))"
        
        switch clockInteractionType {
        case .exact:
                startTimeString = "\(watchFaceDateFormatter.string(from: startDate))"
                endTimeString = "\(watchFaceDateFormatter.string(from: endDate))"
        case .singleRange, .multiRange:
            if ( self.rangedTimes.indices.contains(selectedTimeWedgeIndex)) {
                let wedgeTimes = rangedTimes[selectedTimeWedgeIndex]
                startTimeString = "\(watchFaceDateFormatter.string(from: wedgeTimes.startTime))"
                endTimeString = "\(watchFaceDateFormatter.string(from: wedgeTimes.endTime))"
            }
        }
        
        
        let startTimeRect = (startTimeString as NSString).boundingRect(with: titleTextInset.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.clockFaceFont], context: nil)
        let endTimeRect = (endTimeString as NSString).boundingRect(with: titleTextInset.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: self.clockFaceFont], context: nil)
        
        var startTimePosition = layer.center
        var endTimePosition = layer.center
        
        let centerSpacerHeight = CGFloat(22.0)
        
        switch clockInteractionType {
        case .multiRange:
            startTimePosition = CGPoint(x: layer.center.x, y: layer.center.y - centerSpacerHeight)
            endTimePosition = CGPoint(x: layer.center.x, y: layer.center.y + centerSpacerHeight)
        default:
            break
            
        }
        
        startTimeTextLayer.string = startTimeString
        startTimeTextLayer.bounds.size = startTimeRect.size
        startTimeTextLayer.position = startTimePosition
        
        endTimeTextLayer.string = endTimeString
        endTimeTextLayer.bounds.size = endTimeRect.size
        endTimeTextLayer.position = endTimePosition

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
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !disabled  else {
        		pointMover = nil
            return
        }
        
        
//        var prev = pointOfTouch
        let pointerMoverProducer: (@escaping (CGPoint) -> Angle, @escaping (Angle)->()) -> (CGPoint) -> () = { g, s in
            return { p in
                let c = self.layer.center
                let computedP = CGPoint(x: p.x, y: self.layer.bounds.height - p.y)
                let v1 = CGVector(from: c, to: computedP)
                let v2 = CGVector(angle:g( p ))

                s(clockDescretization(CGVector.signedTheta(v1, vec2: v2), minuteStep: self.minuteStep, hours: self.clockHourTypeHours))
                self.updateTimesForWedges()
                self.update()
            }

        }
        
        let touch = touches.first!
        let pointOfTouch = touch.location(in: self)
        
        guard let layer = self.overallPathLayer.hitTest( pointOfTouch ) else {
            return
        }
        
        if layer == exactTimeIndicatorTouchLayer {
            if (shouldMoveHead) {
                pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
            } else {
            
                pointMover = nil
            }
        }
        // Check if this layer has a time wedge tag
        else if let identifier = layer.name {
            
            // Apologies:Sorry about the hack! :(
            
            var timeWedgeLayer = layer
            while timeWedgeLayer.superlayer != nil {
                if let wedgeLayer = timeWedgeLayer.superlayer as? TimeWedgeLayer {
                    timeWedgeLayer = wedgeLayer
                    break
                }
                if let superLayer = timeWedgeLayer.superlayer {
                     timeWedgeLayer = superLayer
                } else {
                    super.touchesBegan(touches, with: event)
                    return
                }
            }
            guard let wedgeIndex = timeWedges.index(of: timeWedgeLayer as! TimeWedgeLayer) else {
                super.touchesBegan(touches, with: event)
                return
            }
            
            selectedTimeWedgeIndex = wedgeIndex
            
            switch identifier {
            case TimeWedgeLayer.deleteButtonIdentifierName:
                // Delete this time wedge
                self.removeTimeWedge(at: wedgeIndex)
            case TimeWedgeLayer.wedgeIdentifierName:
                break
                // Get the angles for this wedge and change them
//                pointMover = pointerMoverProducer({ pt in
//                    let x = CGVector(
//                        from: self.bounds.center,
//                        to:CGPoint(x: prev.x, y: self.layer.bounds.height - prev.y)
//                    ).theta;
//                    prev = pt;
//                    return x
//                }, {
//                    // Check angles before setting them
//                    let headAngle = self.rangedAngles[wedgeIndex].headAngle + $0
//                    let tailAngle = self.rangedAngles[wedgeIndex].tailAngle + $0
//                    let endDate = self.angleToTime(headAngle)
//                    let startDate = self.angleToTime(tailAngle)
//                    
//                    if endDate.isGreaterThanDate(dateToCompare: startDate) {
//                        self.rangedAngles[wedgeIndex].headAngle = headAngle
//                        self.rangedAngles[wedgeIndex].tailAngle = tailAngle
//                    }
//                    
//                })
//                break
            case TimeWedgeLayer.tailIdentifierName:
                // Find the angle
                pointMover = pointerMoverProducer({_ in self.rangedAngles[wedgeIndex].tailAngle},
                                                  {
                                                    // Check angles before setting them
                                                    let headAngle = self.rangedAngles[wedgeIndex].headAngle
                                                    let tailAngle = self.rangedAngles[wedgeIndex].tailAngle + $0
                                                    let endDate = self.angleToTime(headAngle)
                                                    let startDate = self.angleToTime(tailAngle)
                                                    
                                                    if endDate.isGreaterThanDate(dateToCompare: startDate) {
                                                        self.rangedAngles[wedgeIndex].headAngle = headAngle
                                                        self.rangedAngles[wedgeIndex].tailAngle = tailAngle
                                                    }
                                                }
                )
                break
            case TimeWedgeLayer.headIdentifierName:
                pointMover = pointerMoverProducer({ _ in self.rangedAngles[wedgeIndex].headAngle},
                                                  {
                                                    // Check angles before setting them
                                                    let headAngle = self.rangedAngles[wedgeIndex].headAngle + $0
                                                    let tailAngle = self.rangedAngles[wedgeIndex].tailAngle
                                                    let endDate = self.angleToTime(headAngle)
                                                    let startDate = self.angleToTime(tailAngle)
                                                    
                                                    if endDate.isGreaterThanDate(dateToCompare: startDate) {
                                                        self.rangedAngles[wedgeIndex].headAngle = headAngle
                                                        self.rangedAngles[wedgeIndex].tailAngle = tailAngle
                                                    }
                                                }
                )
                break
            default:
                break
            
                
            }
        }
        
        else if let _ = self.trackLayer.hitTest( pointOfTouch ) {
            if clockInteractionType == .exact {
                if (shouldMoveHead) {
                    pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
                } else {
                    
                    pointMover = nil
                }
            } else {
                // Create a new segment here
                let angleOfTap = CGVector(
                    from: self.bounds.center,
                    to:CGPoint(x: pointOfTouch.x, y: self.layer.bounds.height - pointOfTouch.y)
                    ).theta
                self.addTimeRangeAtPoint(angle: angleOfTap)
                
                pointMover = nil
                //                pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
                
                //                self.addTimeRangeAtPoint(angle: )
            }
        }

        super.touchesBegan(touches, with: event)

    }
    
    override open  func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pointMover = nil
        switch clockInteractionType {
        case .exact:
            delegate?.timesChanged(self, startDate: self.startDate, endDate: endDate)
        case .multiRange, .singleRange:
            delegate?.rangedTimesChanged(self, rangedTimes: self.rangedTimes, selectedIndex: selectedTimeWedgeIndex)
        }
        
        super.touchesEnded(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let pointMover = pointMover else { return }
        pointMover(touch.location(in: self))
        switch clockInteractionType {
        case .exact:
            delegate?.timesUpdated(self, startDate: self.startDate, endDate: endDate)
        case .multiRange, .singleRange:
            delegate?.rangedTimesUpdated(self, rangedTimes: self.rangedTimes, selectedIndex: selectedTimeWedgeIndex)
        }
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
    func angleToTime(_ angle: Angle) -> Date {
        let dAngle = Double(angle)
        let min = CGFloat(((M_PI_2 - dAngle) / (2 * M_PI)) * (Double(clockHourTypeHours) * 60))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let stepSize: CGFloat = CGFloat(self.minuteStep)
        let date = self.calendar.date(byAdding: .minute, value: Int(medStepFunction(min, stepSize: stepSize/* minute steps*/)), to: startOfToday)!
        // Now constrain the date
        let units : Set<Calendar.Component> = [.hour, .minute]
        let components = self.calendar.dateComponents(units, from: date)
        return self.calendar.date(from: components)!
    }
}
