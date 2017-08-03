//
//  WKNotificationStructs.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation


public struct HeaderViewNotification {
    let type: HeaderViewStatusBarType
    let text: String
    let autoHide: Bool
    
    init(type:HeaderViewStatusBarType, text:String, autoHide:Bool) {
        self.type = type
        self.text = text
        self.autoHide = autoHide
    }
    
    init(userInfo:[AnyHashable: Any]) {
        self.type = HeaderViewStatusBarType(rawValue: userInfo["type"] as! String)!
        self.text = userInfo["text"] as! String
        self.autoHide = userInfo["autoHide"] as! Bool
    }
    
    func userInfo() -> [NSObject:AnyObject] {
        return ["type" as NSObject:self.type.rawValue as AnyObject,
                "text" as NSObject:self.text as AnyObject,
                "autoHide" as NSObject: self.autoHide as AnyObject
        ]
    }

}
