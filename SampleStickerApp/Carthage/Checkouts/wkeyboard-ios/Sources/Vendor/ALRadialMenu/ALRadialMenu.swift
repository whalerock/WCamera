//
//  ALRadialMenu.swift
//  ALRadialMenu
//
//  Created by Alex Littlejohn on 2015/04/26.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit

private typealias ALAnimationsClosure = () -> Void

private struct Angle {
    var degrees: Double
    
    func radians() -> Double {
        return degrees * (M_PI/180)
    }
}

open class ALRadialMenu: UIButton {
    
    // MARK: Public API
    
    public convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /**
    Set a delay to stagger the showing of each subsequent radial button
    
    Note: this is a bit buggy when using UIView animations
    
    Default = 0
    
    - parameter Double: The delay in seconds
    */
    open func setDelay(_ delay: Double) -> Self {
        self.delay = delay
        return self
    }
    
    /**
    Set the buttons to display when present is called. Each button should be an instance of ALRadialMenuButton
    
    - parameter Array: An array of ALRadialMenuButton instances
    */
    open func setButtons(_ buttons: [ALRadialMenuButton]) -> Self {
        self.buttons = buttons
        
        for i in 0..<buttons.count {
            let button = buttons[i]
            let action = button.action
            
            button.center = center
            button.action = {
                self._dismiss(i)
                if let a = action {
                    a()
                }
            }
        }
        
        return self
    }
    
    /**
    Set to false to disable dismissing the menu on background tap
    
    Default = true
    
    - parameter Bool: enabled or disable the gesture
    */
    open func setDismissOnOverlayTap(_ dismissOnOverlayTap: Bool) -> Self {
        self.dismissOnOverlayTap = dismissOnOverlayTap
        return self
    }
    
    /**
    Set the radius to control how far from the point of origin the buttons should show when the menu is open
    
    Default = 100
    
    - parameter Double: the radius in pts
    */
    open func setRadius(_ radius: Double) -> Self {
        self.radius = radius
        return self
    }
    
    /**
    Set the starting angle from which to lay out the buttons
    
    Default = 270
    
    - parameter Double: the angle in degrees
    */
    open func setStartAngle(_ degrees: Double) -> Self {
        self.startAngle = Angle(degrees: degrees)
        return self
    }
    
    /**
    Set the total circumference that the buttons should be laid out in
    
    Default = 360
    
    - parameter Double: the circumference in degrees
    */
    open func setCircumference(_ degrees: Double) -> Self {
        self.circumference = Angle(degrees: degrees)
        return self
    }
    
    /**
    Set the origin point from which the buttons should animate
    
    Default = self.center
    
    - parameter CGPoint: the origin point
    */
    open func setAnimationOrigin(_ animationOrigin: CGPoint) -> Self {
        self.animationOrigin = animationOrigin
        return self
    }
    
    /**
    Present the buttons in the specified view's window
    
    - parameter UIView: view
    */
    open func presentInView(_ view: UIView) -> Self {
        return presentInWindow(view.window!)
    }
    
    /**
    Present the buttons in the specified window
    
    - parameter UIWindow: window
    */
    open func presentInWindow(_ win: UIWindow) -> Self {
        
        if buttons.count == 0 {
            print("ALRadialMenu has no buttons to present")
            return self
        }
        
        if animationOrigin == nil {
            animationOrigin = center
        }
        
        win.addSubview(overlayView)
        
        for i in 0..<buttons.count {
            
            let button = buttons[i]
            
            win.addSubview(button)
            presentAnimation(button, index: i)
        }
        
        return self
    }
    
    /**
    Dismiss the buttons with an animation
    */
    open func dismiss() {
        
        if buttons.count == 0 {
            print("ALRadialMenu has no buttons to dismiss")
            return
        }
        
        _dismiss(-1)
    }
    
    // MARK: private vars
    
    fileprivate var delay: Double = 0
    fileprivate var buttons = [ALRadialMenuButton]() {
        didSet {
            calculateSpacing()
        }
    }
    
    fileprivate var dismissOnOverlayTap = true {
        didSet {
            if let gesture = dismissGesture {
                gesture.isEnabled = dismissOnOverlayTap
            }
        }
    }
    
    fileprivate var overlayView = UIView(frame: UIScreen.main.bounds)
    
    fileprivate var radius: Double = 100
    fileprivate var startAngle: Angle = Angle(degrees: 270)
    fileprivate var circumference: Angle = Angle(degrees: 360) {
        didSet {
            calculateSpacing()
        }
    }
    
    fileprivate var spacingDegrees: Angle!
    fileprivate var animationOrigin: CGPoint!
    
    fileprivate var dismissGesture: UITapGestureRecognizer!
    fileprivate var animationOptions: UIViewAnimationOptions = UIViewAnimationOptions.beginFromCurrentState

    // MARK: Private API
    fileprivate func commonInit() {
        dismissGesture = UITapGestureRecognizer(target: self, action: #selector(ALRadialMenu.dismiss))
        dismissGesture.isEnabled = dismissOnOverlayTap
        
        overlayView.addGestureRecognizer(dismissGesture)
    }
    
    fileprivate func _dismiss(_ selectedIndex: Int) {
        
        overlayView.removeFromSuperview()
        
        for i in 0..<buttons.count {
            if i == selectedIndex {
                selectedAnimation(buttons[i])
            } else {
                dismissAnimation(buttons[i], index: i)
            }
        }
    }
    
    fileprivate func presentAnimation(_ view: ALRadialMenuButton, index: Int) {
        let degrees = startAngle.degrees + spacingDegrees.degrees * Double(index)
        let newCenter = pointOnCircumference(animationOrigin, radius: radius, angle: Angle(degrees: degrees))
        let _delay = Double(index) * delay
        
        view.center = animationOrigin
        view.alpha = 0
        UIView.animate(withDuration: 0.5, delay: _delay, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: animationOptions, animations: {
            view.alpha = 1
            view.center = newCenter
        }, completion: nil)
    }
    
    fileprivate func dismissAnimation(_ view: ALRadialMenuButton, index: Int) {
        let _delay = Double(index) * delay
        UIView.animate(withDuration: 0.5, delay: _delay, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: animationOptions, animations: {
            view.alpha = 0
            view.center = self.animationOrigin
        }, completion: { finished in
            view.removeFromSuperview()
        })
    }
    
    fileprivate func selectedAnimation(_ view: ALRadialMenuButton) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: animationOptions, animations: {
            view.alpha = 0
            view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: { finished in
            view.transform = CGAffineTransform.identity
            view.removeFromSuperview()
        })
    }
    
    fileprivate func pointOnCircumference(_ origin: CGPoint, radius: Double, angle: Angle) -> CGPoint {
        
        let radians = angle.radians()
        let x = origin.x + CGFloat(radius) * CGFloat(cos(radians))
        let y = origin.y + CGFloat(radius) * CGFloat(sin(radians))
        
        return CGPoint(x: x, y: y)
    }
    
    fileprivate func calculateSpacing() {
        if buttons.count > 0 {
            
            var c = buttons.count
            
            if circumference.degrees < 360 && c > 1{
                c -= 1
            }
            
            spacingDegrees = Angle(degrees: circumference.degrees / Double(c))
        }
    }
}
