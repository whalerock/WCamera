//
//  WUtilities.swift
//  WUtilities
//
//  Created by aramik on 7/16/16.
//  Copyright © 2016 Whalerock Industries. All rights reserved.
//

import Foundation

open class WUtilities {

    open static let deviceInfo = WDeviceInfo()
    open static let location = WLocation()

    fileprivate init() {
        
    }

    open static func getValueFromPLIST(key:String, file:String, ofType:String, path:String? = nil) -> String? {
        var myDict: NSDictionary?
        if let filePath = path {
            myDict = NSDictionary(contentsOf: URL(string: filePath)!)
        } else if let path = Bundle.main.path(forResource: file, ofType: ofType) {
            myDict = NSDictionary(contentsOfFile: path)
        }

        if let dict = myDict {
            if let valueForKey = dict.value(forKey: key) {
                return valueForKey as? String
            }
        }
        return nil
    }
}
