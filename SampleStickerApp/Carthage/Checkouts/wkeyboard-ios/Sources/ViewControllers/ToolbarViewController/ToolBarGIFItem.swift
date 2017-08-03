//
//  ToolBarCustomBrandGIFButton.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WAssetManager

open class ToolBarGIFItem: UIBarButtonItem {
    
    open var gifImage: FLAnimatedImageView!
    open var customButton: ToolBarIconButton!
    
    fileprivate override init() {
        super.init()
    }
    
    convenience init(url:String, tag:Int,  action: Selector, target:AnyObject) {
        self.init()
        
        self.customButton = ToolBarIconButton(type: .custom)
        customButton.addTarget(target, action: action, for: .touchUpInside)
        customButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        customButton.tag = tag
        self.tag = tag
        self.customView = customButton
        self.setAnimatedGIF(url)
    }
    
    convenience init(image: String, selectedImage: String, tag:Int,  action: Selector, target:AnyObject) {
        self.init()
        
        self.customButton = ToolBarIconButton(type: .custom)
        customButton.addTarget(target, action: action, for: .touchUpInside)
        customButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        customButton.tag = tag
        self.tag = tag
        self.customView = customButton
        self.setAnimatedGIF(image: image, selectedImage: selectedImage)
    }
    
    fileprivate func setAnimatedGIF(_ url:String) {
        self.gifImage = FLAnimatedImageView()
        self.gifImage.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        self.gifImage.isUserInteractionEnabled = false
        self.customView!.addSubview(self.gifImage)
        
        if let cachedURL = WAssetManager.sharedInstance.localPathForAsset(fromUrl: url) {
            if let animatedData = try? Data(contentsOf: URL(fileURLWithPath: cachedURL)) {
                let animatedImage = FLAnimatedImage(animatedGIFData: animatedData)
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.gifImage.animatedImage = animatedImage
                    
                })
                
            }
        }
    }
    
    fileprivate func setAnimatedGIF(image:String, selectedImage: String) {
        self.gifImage = FLAnimatedImageView()
        self.gifImage.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        self.gifImage.isUserInteractionEnabled = false
        self.customView!.addSubview(self.gifImage)
        
        let imagePath = Bundle.main.path(forResource: image, ofType: "gif")
        //let selectedImagePath = Bundle.main.path(forResource: selectedImage, ofType: "gif")
    
        if let animatedData = try? Data(contentsOf: URL(fileURLWithPath: imagePath!)) {
            let animatedImage = FLAnimatedImage(animatedGIFData: animatedData)
            DispatchQueue.main.async(execute: { [weak self] in
                self?.gifImage.animatedImage = animatedImage

            })

        }
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
