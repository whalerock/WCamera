//
//  HVStatusBarStyle.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation


public enum HeaderViewStatusBarType:String {
    case Default = "Default"
    case Notification = "Notification"
    
    typealias Metrics = (top: CGFloat, height: CGFloat)
    typealias Styles = (backgroundColor: UIColor, textColor:UIColor, borderRadius:CGFloat)
    
    var metrics: Metrics {
        switch self {
        case .Default: return Metrics(0, 30)
        case .Notification: return Metrics(5, 20)
        }
    }
    
    var style: Styles {
        switch self {
        case .Default: return Styles(UIColor.clear,
                                     UIColor.black.withAlphaComponent(0.8),
                                     5)
        case .Notification: return Styles(WKConfig.sharedInstance.toolbarBackgroundColor,
                                          UIColor.white,
                                          5)
        }
    }
}

