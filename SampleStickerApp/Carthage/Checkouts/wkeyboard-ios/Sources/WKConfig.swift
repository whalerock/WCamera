//
//  WKConstants.swift
//  Kimoji
//
//  Created by aramik on 6/8/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

open class WKConfig: NSObject {
    open static let sharedInstance = WKConfig()
    open var api: String = ""
    open var keyboardName: String = ""
    open var wantsThumbnailsForCell = true
    open var wantsToolbarItemsAlwaysTemplate = true
    open var wantsToolbarSelectedIndicator = true
    open var toolbarBackgroundColor: UIColor = UIColor.clear
    open var toolbarTintColor: UIColor = UIColor.white
    open var toolbarSelectedTintColor = UIColor.white
    open var containerAppDomain: String = ""
    open var buttonURL: String = ""
    open var emojiCollectionViewDirection: String = "horizontal"
    open var wantsFavoritesEnabled = false
    open var wantsToolbarImagesFromCMS = true
    open var wantsCategoryImagesFromCMS = true
    open var wantsTemplateImageForActiveCategory = false
    open var categoryInactiveOpacity: CGFloat = 0.3
    open var templateImageTintHexColor: String = "000000"
    open var toolbarButtonCustomImageInsets: [UIEdgeInsets]?
    open var emojiImageCustomInset: UIEdgeInsets?
    open var isImessageExtension = false
    open var isContainerApp = false
    open var useCategoryBackgroundImage = false
    open var showKeywordController = true
}




