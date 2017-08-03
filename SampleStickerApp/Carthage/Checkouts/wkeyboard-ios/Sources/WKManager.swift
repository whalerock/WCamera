//
//  WKManager.swift
//  Kimoji
//
//  Created by aramik on 6/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}




public protocol WKManagerDelegate: class {
    func selectionUpdated(_ index:Int)
}



open class WKManager {
    open static let sharedInstance = WKManager()
    open weak var delegate: WKManagerDelegate?

   
    open var types: [WKType]?
    open var categories: [WKCategory]?
    open var keywordAssets = [WKAsset]()


    open var selectedIndex: Int = 0 {
        didSet {
            self.delegate?.selectionUpdated(self.selectedIndex)
        }
    }

    open var selectedType: WKType? {
        get {
            guard self.types?.count > 0,
                self.selectedIndex < self.types?.count else {
                return nil
            }
            return self.types?[self.selectedIndex]
        }
    }
    
    open func getTypeTitle(_ id:String?) -> String {
        guard types != nil && id != nil else { return "" }
        for type in types! {
            if type.id == id {
                return type.title!
            }
        }
        return ""
    }
    
    
    open func getCategoryTitle(_ id:String?) -> String {
        guard categories != nil && id != nil else { return "" }
        for category in categories! {
            if category.id == id {
                return category.title
            }
        }
        return ""
    }
}


public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
