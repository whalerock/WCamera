//
//  CategoryCell.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit

open class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var iconViewBackgroundImage: UIImageView!

    var indexPath: IndexPath?
    
    open var isSelectionHighlighted: Bool = false {
        didSet {
            if isSelectionHighlighted {
                if WKConfig.sharedInstance.wantsTemplateImageForActiveCategory {
                    let templatedImage = iconView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                    iconView.tintColor = UIColor(hex: WKConfig.sharedInstance.templateImageTintHexColor)
                    iconView.image = templatedImage
                    iconView.alpha = 1.0
                } else {
                    if WKConfig.sharedInstance.wantsCategoryImagesFromCMS {
                        self.iconView.alpha = 1.0
                        if WKConfig.sharedInstance.useCategoryBackgroundImage {
                            self.iconViewBackgroundImage?.alpha = 1
                        }
                    } else {
                        if let assetImage = UIImage(named: "Category\(indexPath!.row)_active") {
                            iconView.image = assetImage
                        }
                    }
                }
            } else {
                if WKConfig.sharedInstance.wantsTemplateImageForActiveCategory {
                    let originalImage = iconView.image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                    iconView.image = originalImage
                    iconView.alpha = WKConfig.sharedInstance.categoryInactiveOpacity
                } else {
                    if WKConfig.sharedInstance.wantsCategoryImagesFromCMS {
                        self.iconView.alpha = WKConfig.sharedInstance.categoryInactiveOpacity
                        if WKConfig.sharedInstance.useCategoryBackgroundImage {
                            self.iconViewBackgroundImage?.alpha = 0
                        }
                    } else {
                        if let assetImage = UIImage(named: "Category\(indexPath!.row)_inactive") {
                            iconView.image = assetImage
                        }
                    }
                }
            }
        }
    }
    
}
