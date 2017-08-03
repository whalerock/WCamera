//
//  CircularProgressView.swift
//  CircularProgressView
//
//  Created by Chris Amanse on 1/13/16.
//  Copyright © 2016 Joe Christopher Paul Amanse. All rights reserved.
//

import UIKit

@IBDesignable
open class CircularProgressView: UIView {
    internal let trackLayer = CAShapeLayer()
    internal let progressLayer = CAShapeLayer()
    
    // MARK: Inspectable
    
    @IBInspectable open var trackWidth: CGFloat = 2 {
        didSet {
            layoutTrackLayer()
        }
    }
    @IBInspectable open var progressWidth: CGFloat = 2 {
        didSet {
            layoutProgressLayer()
        }
    }
    
    @IBInspectable open var trackTintColor: UIColor? = UIColor.lightGray {
        didSet {
            colorTrackLayer()
        }
    }
    @IBInspectable open var progressTintColor: UIColor? = UIColor.darkGray {
        didSet {
            colorProgressLayer()
        }
    }
    
    @IBInspectable open var progress: Float = 0 {
        didSet {
            // Pin values between [0,1]
            if progress < 0 {
                progress = 0
            } else if progress > 1 {
                progress = 1
            } else {
                // Valid value, update stroke
                updateProgressStroke()
            }
        }
    }
    
    // MARK: Drawing properties
    
    fileprivate func circleRadiusWithStrokeWidth(_ strokeWidth: CGFloat, withinSize size: CGSize) -> CGFloat {
        let width = size.width
        let height = size.height
        
        let length = width > height ? height : width
        return (length - strokeWidth) / 2
    }
    fileprivate func circleFrameWithStrokeWidth(_ strokeWidth: CGFloat, withRadius radius: CGFloat, withinSize size: CGSize) -> CGRect {
        let width = size.width
        let height = size.height
        
        let x: CGFloat
        let y: CGFloat
        
        if width > height {
            y = strokeWidth / 2
            x = (width / 2) - radius
        } else {
            x = strokeWidth / 2
            y = (height / 2) - radius
        }
        
        let diameter = 2 * radius
        return CGRect(x: x, y: y, width: diameter, height: diameter)
    }
    internal var trackPath: UIBezierPath {
        let size = bounds.size
        let radius = circleRadiusWithStrokeWidth(trackWidth, withinSize: size)
        
        return UIBezierPath(ovalIn: circleFrameWithStrokeWidth(trackWidth, withRadius: radius, withinSize: size))
    }
    internal var progressPath: UIBezierPath {
        let progressPath = UIBezierPath()
        
        let radius = circleRadiusWithStrokeWidth(progressWidth, withinSize: bounds.size)
        let frame = circleFrameWithStrokeWidth(progressWidth, withRadius: radius, withinSize: bounds.size)
        let frameCenter = CGPoint(x: (frame.width / 2) + frame.origin.x, y: (frame.height / 2) + frame.origin.y)
        
        progressPath.move(to: CGPoint(x: frameCenter.x, y: frameCenter.y - radius))
        progressPath.addArc(withCenter: frameCenter,
            radius: radius,
            startAngle: CGFloat(-M_PI_2),
            endAngle: CGFloat((2 * M_PI) - M_PI_2),
            clockwise: true)
        
        return progressPath
    }
    
    // MARK: Initialization
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        customInitialization()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        customInitialization()
    }
    
    public init(frame: CGRect, progress: Float = 0, trackWidth: CGFloat = 2, progressWidth: CGFloat = 2,
        trackTintColor: UIColor, progressTintColor: UIColor) {
            super.init(frame: frame)
            
            self.trackWidth = trackWidth
            self.progressWidth = progressWidth
            self.trackTintColor = trackTintColor
            self.progressTintColor = progressTintColor
            self.progress = progress
            
            customInitialization()
    }
    convenience public init(frame: CGRect, progress: Float = 0, trackWidth: CGFloat, progressWidth: CGFloat) {
        self.init(frame: frame, progress: progress, trackWidth: trackWidth, progressWidth: progressWidth,
            trackTintColor: UIColor.lightGray, progressTintColor: UIColor.darkGray)
    }
    
    convenience public init(frame: CGRect, progress: Float = 0, circleWidth: CGFloat) {
        self.init(frame: frame, progress: progress, trackWidth: circleWidth, progressWidth: circleWidth)
    }
    
    fileprivate func customInitialization() {
        let clearCGColor = UIColor.clear.cgColor
        
        trackLayer.fillColor = clearCGColor
        colorTrackLayer()
        layoutTrackLayer()
        
        progressLayer.fillColor = clearCGColor
        
        colorProgressLayer()
        layoutProgressLayer()
        updateProgressStroke()
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
    }
    
    // MARK: Layout and color
    
    open override func layoutSubviews() {
        layoutTrackLayer()
        layoutProgressLayer()
    }
    
    fileprivate func layoutTrackLayer() {
        trackLayer.frame = bounds
        trackLayer.lineWidth = trackWidth
        trackLayer.path = trackPath.cgPath
    }
    fileprivate func colorTrackLayer() {
        trackLayer.strokeColor = trackTintColor?.cgColor
    }
    
    fileprivate func layoutProgressLayer() {
        progressLayer.frame = bounds
        progressLayer.lineWidth = progressWidth
        progressLayer.path = progressPath.cgPath
    }
    fileprivate func colorProgressLayer() {
        progressLayer.strokeColor = progressTintColor?.cgColor
    }
    fileprivate func updateProgressStroke() {
        progressLayer.strokeEnd = CGFloat(progress)
    }
    
    // MARK: Interface builder
    open override func prepareForInterfaceBuilder() {
        customInitialization()
    }
}
