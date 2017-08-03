////
////  UIBarButtonItem.swift
////  WAnalytics
////
////  Created by Aramik on 7/21/16.
////  Copyright © 2016 Aramik. All rights reserved.
////
//
///**
// Extension for UIBarButtonItem, only includes functions to inject tracking. WAnalyticsTrackingProperties are added view UIBarItem.
// */
//public extension UIBarButtonItem {
//    
//    /**
//     Used the awakeFromNib to initiate method swizzeling to inject automated tracking for when the buttons action is triggered.
//     
//     - TODO: Make sure awakeFromNib gets called when programatically creating UIBarButtonItem Instance.  Also maybe check to see if there's a KVO that can be monitored rather than method swizzeling.
//     */
//    public override func awakeFromNib() {
//        print("here")
//        
//        let originalTarget = self.target
//        let originalSelector = self.action
//        
//        self.target = self
//        
//        let replacementSelector = #selector(UIBarButtonItem.wa_replacementSelector(_:))
//        let swizzledSelector = #selector(UIBarButtonItem.wa_buttonPressed(_:))
//        
//        let originalMethod = class_getInstanceMethod(originalTarget?.classForKeyedArchiver, originalSelector)
//        let swizzledMethod = class_getInstanceMethod(self.classForKeyedArchiver, swizzledSelector)
//        
//        let didAddMethod = class_addMethod(self.classForKeyedArchiver, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
//        
//        if didAddMethod {
//            class_replaceMethod(self.target?.classForKeyedArchiver, replacementSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//            class_replaceMethod(self.classForKeyedArchiver, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//            
//        }
//        super.awakeFromNib()
//    }
//    
//    /**
//     Triggers a tracking event to WAnalytics, only if trackingProperties are available.
//     
//     - parameter sender: sender from action
//     */
//    public func wa_buttonPressed(sender:AnyObject) {
//        if trackingProperties != nil {
//           // WAnalytics.manager.trackEvent(.All, properties: trackingProperties!)
//        }
//        self.wa_replacementSelector(sender)
//    }
//    
//    /**
//     Placeholder function used for it's implementation during 'method swizzeling'
//     
//     - parameter sender: sender from action
//     */
//    public func wa_replacementSelector(sender:AnyObject) {
//        // Left blank intentionally
//    }
//}
