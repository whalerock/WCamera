//
//  CategoryItem.swift
//  Kimoji
//
//  Created by aramik on 3/16/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit

open class WKCategory: WModel {
    
    open var id: String!
    open var title: String!
    open var assetUrl: String!
    open var position: Int!
    open var color: String?

    public init?(json:NSDictionary?) {
        super.init()
        guard
            let id = json?.value(forKey: "id") as? String,
            let title = json?.value(forKey: "title") as? String,
            let assetUrl = json?.value(forKey: "imageURL") as? String,
            let position = json?.value(forKey: "position") as? Int
        else { return nil }

        self.id = id
        self.title = title
        self.assetUrl = assetUrl
        self.position = position
        self.color = json?.value(forKey: "color") as? String

    }

}
