////
////  UIViewController.swift
////  WAnalytics
////
////  Created by Aramik on 7/20/16.
////  Copyright © 2016 Aramik. All rights reserved.
////
//
///** 
// These properties are accessable programatically and via storyboards.
//*/
//public extension UIViewController {
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
//    /// Comparable to WAnalyticsTrackingProperties.trackingAction; Available programatically and via storyboards.  Has a default value that can be overwritten.
//    @IBInspectable public var waAction: String? {
//        get {
//            if let _ = objc_getAssociatedObject(self, &WAnalyticsProperties.trackingAction) as? String {
//                return objc_getAssociatedObject(self, &WAnalyticsProperties.trackingAction) as? String
//            } else {
//                return "opened"
//            }
//        }
//        set {
//            guard let trackingAction = newValue else { return }
//            objc_setAssociatedObject(self, &WAnalyticsProperties.trackingAction, trackingAction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//    
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
//     By overriding the this function, we are able to something called method-swizzling.  Basically we're taking the implementation for our function and switching with the viewDidAppear.
//     */
//    public override class func initialize() {
//        struct Static {
//            static var token: dispatch_once_t = 0
//        }
//       
//        // make sure this isn't a subclass
//        if self !== UIViewController.self {
//            return
//        }
//        
//        dispatch_once(&Static.token) {
//            let originalSelector = #selector(UIViewController.viewDidAppear(_:))
//            let swizzledSelector = #selector(UIViewController.wa_viewDidAppear(_:))
//            
//            let originalMethod = class_getInstanceMethod(self, originalSelector)
//            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
//            
//            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
//            
//            if didAddMethod {
//                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//            } else {
//                method_exchangeImplementations(originalMethod, swizzledMethod)
//            }
//        }
//        
//    }
//    
//    /**
//     Used to for it's implementation for 'swizzling' with the original.
//     */
//    func wa_viewDidAppear(animated: Bool) {
//        if let properties = trackingProperties {
//            //WAnalytics.manager.trackScreen(.All, name: properties.trackingID)
//            //WAnalytics.manager.trackEvent(.All, properties: trackingProperties!)
//        }
//    }
//    
//  
//}