//
//  BrandAsset.swift
//  Kimoji
//
//  Created by aramik on 3/1/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WUtilities


open class WKAsset: WModel {

    open var id: String!
    open var type: String!
    open var pack: String!
    open var category: String!
    open var title: String!
    open var assetUrl: String!
    open var thumbnailUrl: String!
    open var tracking: String!
    open var position: Int!
    open var keywords: NSArray!
    open var tones: [WKAssetTone]?
    open var explicit: Bool!

    open var hasTones: Bool {
        get {
            guard let tones = self.tones else {
                return false
            }
            return tones.count > 0
        }
    }

    public init?(json:NSDictionary?) {
        super.init()
        
        guard
            let id = json?.value(forKey: "id") as? String,
            let type = json?.value(forKey: "type") as? String,
            let pack = json?.value(forKey: "pack") as? String,
            let title = json?.value(forKey: "title") as? String,
            let category = json?.value(forKey: "category") as? String,
            let tracking = json?.value(forKey: "tracking") as? String,
            let assetUrl = json?.value(forKey: "asset_url") as? String,
            let position = json?.value(forKey: "position") as? Int,
            let keywords = json?.value(forKey: "keywords") as? NSArray,
            let tones = json?.value(forKey: "tones") as? NSArray
            //let isIOS = json?.value(forKey: "isIOS") as? Bool , isIOS == true
        else { return nil }

        self.id = id
        self.type = type
        self.pack = pack
        self.category = category
        self.title = title
        self.assetUrl = assetUrl
        self.tracking = tracking
        self.position = position
        self.keywords = keywords
        self.explicit = (json?.value(forKey: "filter") as? Bool) ?? false

        if let thumbnailUrl = json?.value(forKey: "thumbnail") as? String , thumbnailUrl != ""  {
            self.thumbnailUrl = thumbnailUrl
        } else {
            self.thumbnailUrl = self.assetUrl
        }

        var allTones = [WKAssetTone]()
        for tone in tones {
            if let wkAssetTone = WKAssetTone(json: tone as? NSDictionary) {
                    allTones.append(wkAssetTone)
            }
        }
        self.tones = allTones

    }



}
