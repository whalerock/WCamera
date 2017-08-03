//
//  ToolBarIconItem.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit
import WAssetManager

open class ToolBarIconItem: UIBarButtonItem {
    
    open var customButton: ToolBarIconButton!

    fileprivate override init() {
        super.init()
    }
    
    convenience init?(url:String, tag:Int,  action: Selector, target:AnyObject) {
        self.init()
        guard
            let resourcePath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: url)
            else { return nil }

        self.customButton = ToolBarIconButton(type: .custom)
        customButton.addTarget(target, action: action, for: .touchUpInside)
        
        var image = UIImage(contentsOfFile: resourcePath)
        if WKConfig.sharedInstance.wantsToolbarItemsAlwaysTemplate {
            image = UIImage(contentsOfFile: resourcePath)?.withRenderingMode(.alwaysTemplate)
        }
        customButton.setImage( image, for: .normal)
        
        customButton.imageView?.contentMode = .scaleAspectFit
        customButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        if let customImageInsets = WKConfig.sharedInstance.toolbarButtonCustomImageInsets {
            let imageInsets = customImageInsets[tag]
            customButton.imageEdgeInsets = imageInsets
        }
        
        self.customView?.frame = customButton.frame
        customButton.tag = tag
        self.tag = tag
        self.customView = customButton
        
    }
    
    convenience init?(image:String, selectedImage: String, tag:Int,  action: Selector, target:AnyObject) {
        self.init()
        
        self.customButton = ToolBarIconButton(type: .custom)
        customButton.addTarget(target, action: action, for: .touchUpInside)
        
        var _image = UIImage(named: image)
        var _selectedImage = UIImage(named: selectedImage)
        if WKConfig.sharedInstance.wantsToolbarItemsAlwaysTemplate {
            _image = UIImage(named: image)?.withRenderingMode(.alwaysTemplate)
            _selectedImage = UIImage(named: selectedImage)?.withRenderingMode(.alwaysTemplate)
        }
        customButton.setImage( _image, for: .normal)
        customButton.setImage( _selectedImage, for: .highlighted)
        customButton.setImage( _selectedImage, for: .selected)
        
        if let customImageInsets = WKConfig.sharedInstance.toolbarButtonCustomImageInsets {
            let imageInsets = customImageInsets[tag]
            customButton.imageEdgeInsets = imageInsets
        }
        
        customButton.imageView?.contentMode = .scaleAspectFit
        customButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        self.customView?.frame = customButton.frame
        customButton.tag = tag
        self.tag = tag
        self.customView = customButton
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
