//
//  BrandTab.swift
//  Kimoji
//
//  Created by aramik on 3/1/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit


open class WKType: WModel {

    open var id: String?
    open var position: Int?
    open var title: String?
    open var assetUrl: String?
    open var categories: [WKCategory]?
    open var assets: [[WKAsset]]?
    open var display: Display?

    open class Display {
        open var size: CGSize?
        open var rows: Int?
    }
    
    public override init() {
        super.init()
    }

    public init?(json: NSDictionary?) {
        super.init()
        
        guard
            let id = json?.value(forKey: "id") as? String,
            let position = json?.value(forKey: "position") as? Int,
            let title = json?.value(forKey: "title") as? String,
            let assetUrl = json?.value(forKey: "imageURL") as? String,
            let displaySizeWidth = json?.value(forKeyPath: "display.size.width") as? Int,
            let displaySizeHeight = json?.value(forKeyPath: "display.size.height") as? Int,
            let displayRow = json?.value(forKeyPath: "display.rows") as? Int,
            let isIOS = json?.value(forKey: "isIOS") as? Bool , isIOS == true

        else {

            return nil }


        self.id = id
        self.position = position
        self.title = title
        self.assetUrl = assetUrl
        self.assets = [[WKAsset]]()
        self.categories = [WKCategory]()
        self.display = Display()
        self.display?.size = CGSize(width: CGFloat(displaySizeWidth), height: CGFloat(displaySizeHeight))
        self.display?.rows = displayRow

    }
    
}



