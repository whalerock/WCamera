////
////  UIButton.swift
////  WAnalytics
////
////  Created by Aramik on 7/20/16.
////  Copyright © 2016 Aramik. All rights reserved.
////
//
//import Foundation
//import UIKit
//
///** UIButton extension adds WAnalyticsTrackingProperties to each UIButton component.  These properties are accessable programatically and via storyboards. Automated Event tracking will be sent only if waID and waCateogry are set. The action can be overwritten if need but has a default value that meets tracking requirements.
//*/
//@IBDesignable public extension UIButton {
//    
//    // MARK: Variables
//    
//    /// Comparable to WAnalyticsTrackingProperties.trackingID; Available programatically and via storyboards.
//    @IBInspectable public var waID: String? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingID) as? String
//        }
//        set {
//            guard let trackingID = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingID, trackingID, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Comparable to WAnalyticsTrackingProperties.trackingCateogry; Available programatically and via storyboards.
//    @IBInspectable public var waCategory: String? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingCategory) as? String
//        }
//        set {
//            guard let trackingCategory = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingCategory, trackingCategory, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Comparable to WAnalyticsTrackingProperties.trackingAction; Available programatically and via storyboards.
//    @IBInspectable public var waAction: String? {
//        get {
//            if let _ = objc_getAssociatedObject(self, &WAnalyticsProperties.trackingAction) as? String {
//                return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingAction) as? String
//            } else {
//                return "tapped"
//            }
//        }
//        set {
//            guard let trackingAction = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingAction, trackingAction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Comparable to WAnalyticsTrackingProperties.trackingLabel; Available programatically and via storyboards.
//    @IBInspectable public var waLabel: String? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingLabel) as? String
//        }
//        set {
//            guard let trackingLabel = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingLabel, trackingLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Comparable to WAnalyticsTrackingProperties.trackingContentID; Available programatically and via storyboards.
//    @IBInspectable public var waContentID: String? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingContentID) as? String
//        }
//        set {
//            guard let trackingContentID = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingContentID, trackingContentID, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Used for GoogleAnalytics; Comparable to WAnalyticsTrackingProperties.customDimension; Available programatically and via storyboards.
//    public var waCustomDimension: [String]? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.customDimension) as? [String]
//        }
//        set {
//            guard let customDimension = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.customDimension, customDimension, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Used for NewRelic; Comparable to WAnalyticsTrackingProperties.customInfo; Available programatically and via storyboards.
//    public var waCustomInfo: Dictionary<String,String>? {
//        get {
//            return objc_getAssociatedObject(self, &WAnalyticsProperties.customInfo) as? Dictionary<String,String>
//        }
//        set {
//            guard let customInfo = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.customInfo, customInfo, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
//    /// Read-Only version of WAnalyticsTrackingProperties
//    private var trackingProperties: WAnalyticsTrackingProperties? {
//        get {
//            guard let _trackingProperties = WAnalyticsTrackingProperties(id: waID, category: waCategory, action: waAction, label: waLabel, contentID: waContentID, customDimensions: waCustomDimension, customInfo: waCustomInfo) else {
//                return nil
//            }
//            return _trackingProperties
//        }
//    }
//    
//    // MARK: Overrides
//    /**
//     By overriding this function, it allows us to inject tracking calls before the superview calls the action associated with the buttons target.  Since this should only be for button taps, we've excluded the "perform:" action so storyboard segues don't trigger a tap event.
//     
//     - parameter action: Selector
//     - parameter target: AnyObject
//     - parameter event:  UIEvent
//     */
//    public override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
//        if action.description != "perform:" {
//            if trackingProperties != nil {
//               // WAnalytics.manager.trackEvent(.All, properties: trackingProperties!)
//            }
//        }
//        super.sendAction(action, to: target, forEvent: event)
//    }
//}