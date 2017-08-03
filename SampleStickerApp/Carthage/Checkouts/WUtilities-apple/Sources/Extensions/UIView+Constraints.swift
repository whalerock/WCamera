//
//  UIView+Constraints.swift
//  WUtilities
//
//  Created by aramik on 7/10/16.
//
//

import UIKit

extension UIView {

    /**
     Exention to UIView to get the value of a constant in a given Constraint. Func iterates through all constraints attached to the given view, if no matching constraints are found within the view then iteration of its superview's constraints will begin.

     - parameter identifier: NSLayoutConstraint identifier which must be set either through code or Interface Build

     - returns: value of constant for the given constraint
     */
    public func valueForConstraint(_ identifier:String) -> CGFloat? {

        // Search for constraint in view
        for constraint in self.constraints {
            if constraint.identifier == identifier {
                return constraint.constant
            }
        }

        // If not found, search for constraint in super view
        if let sv = self.superview {
            for constraint in sv.constraints {
                if constraint.identifier == identifier {
                    return constraint.constant
                }
            }
        }

        return nil
    }

    /**
     Exention to UIView to streamline updating value of a constant in a given Constraint along with the optino to have it animated or not.  Also include animation block for a much cleaner, maintainable code base.  Func iterates through all constraints attached to the given view, if no matching constraints are found within the view then iteration of its superview's constraints will begin.

     - parameter identifier: NSLayoutConstraint identifier which must be set either through code or Interface Build
     - parameter value:      New value for the constraints constant
     - parameter animated:   Whether or not the update should be animated
     - parameter duration:   Duration of animation; Default value is set for more consistant animations throughout the app.
     */
    public func setValueForConstraint(_ identifier:String, value:CGFloat, animated:Bool, duration:TimeInterval = 0.8) {
        for constraint in self.constraints {
            if constraint.identifier == identifier {
                constraint.constant = value
            }
        }

        if let sv = self.superview {
            for constraint in sv.constraints {
                if constraint.identifier == identifier {
                    constraint.constant = value
                }
            }
        }

        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: UIViewAnimationOptions(), animations: {
                self.layoutIfNeeded()
                self.superview?.layoutIfNeeded()
                }, completion: nil)
        }
    }
}
