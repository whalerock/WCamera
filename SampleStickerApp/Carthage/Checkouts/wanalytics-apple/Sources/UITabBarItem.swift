////
////  UITabBarItem.swift
////  WAnalytics
////
////  Created by Aramik on 7/21/16.
////  Copyright © 2016 Aramik. All rights reserved.
////
//
///**
// UITabBar extension is used to inject tracking via KVO.
// */
//public extension UITabBar {
//    
//    // MARK: Overrides
//    
//    /**
//     Overrides this function to add a KVO for 'selectedItem' and injects tracking.
//     
//     - TODO:
//        - Make sure awakeFromNib() methods works with programatically created TabBars
//        - Find a way to remove the observer when view is unloading.
//     */
//    public override func awakeFromNib() {
//        addObserver(self, forKeyPath: "selectedItem", options: [NSKeyValueObservingOptions.Initial,.New], context: nil)
//        super.awakeFromNib()
//    }
//    
//    /**
//     Inject tracking when KVO is received.
//     */
//    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        if keyPath == "selectedItem" {
//            if selectedItem?.trackingProperties != nil {
//               // WAnalytics.manager.trackEvent(.All, properties: selectedItem!.trackingProperties!)
//            }
//        }
//    }
//
//}