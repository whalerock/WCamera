//
//  BrandProtocol.swift
//  Kimoji
//
//  Created by aramik on 6/23/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WUtilities

open class WModel {
    open func toDictionary() -> [String:Any] {
        return Mirror(reflecting: self).toDictionary()
    }
}

