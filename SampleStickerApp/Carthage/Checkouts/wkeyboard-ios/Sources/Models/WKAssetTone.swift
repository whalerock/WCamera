//
//  BrandAssetTone.swift
//  Kimoji
//
//  Created by aramik on 4/19/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation


open class WKAssetTone: WModel {

    open var id: String!
    open var type: String!
    open var assetUrl: String!
    open var thumbnailUrl: String!
    open var tracking: String!

    public init?(json:NSDictionary?) {
        super.init()
        guard
            let id = json?.value(forKey: "id") as? String,
            let assetUrl = json?.value(forKey: "asset_url") as? String,
            let thumbnailUrl = json?.value(forKey: "thumbnail") as? String,
            let tracking = json?.value(forKey: "tracking") as? String
        else { return nil }

        self.id = id
        self.assetUrl = assetUrl
        self.thumbnailUrl = thumbnailUrl
        self.tracking = tracking
    }
    
}

