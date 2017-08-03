//
//  BrandPack.swift
//  Kimoji
//
//  Created by aramik on 3/1/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit


open class WKPack: WModel {

    open var payloadID: Int!
    open var position: Int!
    open var id: String!
    open var title: String!
    open var bundleIdentifier: String!
    open var price: String!
    open var description: String!
    open var assetUrl: String!
    open var section: String?
    
    public init?(json:NSDictionary?) {
        super.init()
        guard
            let payloadID = json?.value(forKey: "payload_id") as? Int,
            let id = json?.value(forKey: "id") as? String,
            let title = json?.value(forKey: "title") as? String,
            let bundleIdentifier = json?.value(forKey: "bundleIdentifer") as? String,
            let price = json?.value(forKey: "price") as? String,
            let description = json?.value(forKey: "description") as? String,
            let assetUrl = json?.value(forKey: "asset_url") as? String,
            let position = json?.value(forKey: "position") as? Int
        else { return nil }

        self.payloadID = payloadID
        self.id = id
        self.title = title
        self.bundleIdentifier = bundleIdentifier
        self.price = price
        self.description = description
        self.assetUrl = assetUrl
        self.position = position
        self.section = json?.value(forKey: "section") as? String
    }

}
