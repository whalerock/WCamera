
//
//  EmojiCellView.swift
//  Kimoji
//
//  Created by aramik on 3/20/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit
import WUtilities
import WNetwork
import WAssetManager


public enum EmojiCellViewState {
    case loading
    case missingThumbnail
    case missingAsset
    case active
}

open class EmojiCellView: UICollectionViewCell {
    @IBOutlet weak var bundleName: UILabel!
    
    @IBOutlet public weak var imageView: UIImageView!
    @IBOutlet public weak var gifImageView: FLAnimatedImageView!
    @IBOutlet public weak var spinner: UIActivityIndicatorView!
    
    //fileprivate var queue: OperationQueue!
    fileprivate var state: EmojiCellViewState = .active
    
    open var asset: WKAsset! {
        didSet {
            if WKConfig.sharedInstance.wantsThumbnailsForCell {
                if let cachedAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: self.asset.thumbnailUrl) {
                    if asset.thumbnailUrl.contains(".gif") {
                        DispatchQueue.global().async {
                            if let gifData = try? Data(contentsOf: URL(fileURLWithPath: cachedAssetPath)) {
                                DispatchQueue.main.async {
                                    self.gifImageView?.animatedImage = FLAnimatedImage(animatedGIFData: gifData, optimalFrameCacheSize: 3, predrawingEnabled: false)
                                    self.spinner.stopAnimating()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: URL(fileURLWithPath: cachedAssetPath)) {
                                if let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.imageView.image = image
                                        self.spinner.stopAnimating()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.imageView.backgroundColor = UIColor.lightGray
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.setState(.missingThumbnail)
                }
            } else {
                if let cachedAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: self.asset.assetUrl) {
                    if asset.assetUrl.contains(".gif") {
                        DispatchQueue.global().async {
                            if let gifData = try? Data(contentsOf: URL(fileURLWithPath: cachedAssetPath)) {
                                DispatchQueue.main.async {
                                    self.gifImageView?.animatedImage = FLAnimatedImage(animatedGIFData: gifData, optimalFrameCacheSize: 3, predrawingEnabled: false)
                                    self.spinner.stopAnimating()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: URL(fileURLWithPath: cachedAssetPath)) {
                                if let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.imageView.image = image
                                        self.spinner.stopAnimating()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.imageView.backgroundColor = UIColor.lightGray
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.setState(.missingAsset)
                }
            }
        }
    }
    
    public func adjustFrame() {
        var imageInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        if WKConfig.sharedInstance.emojiImageCustomInset != nil {
            imageInset = WKConfig.sharedInstance.emojiImageCustomInset!
        }
        
        imageView?.topAnchor.constraint(equalTo: self.topAnchor, constant: imageInset.top).isActive = true
        imageView?.leftAnchor.constraint(equalTo: self.leftAnchor, constant: imageInset.left).isActive = true
        imageView?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -imageInset.bottom).isActive = true
        imageView?.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -imageInset.right).isActive = true
        
        gifImageView?.topAnchor.constraint(equalTo: self.topAnchor, constant: imageInset.top).isActive = true
        gifImageView?.leftAnchor.constraint(equalTo: self.leftAnchor, constant: imageInset.left).isActive = true
        gifImageView?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -imageInset.bottom).isActive = true
        gifImageView?.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -imageInset.right).isActive = true
    }
    
    open func setState(_ state:EmojiCellViewState) {
        guard self.state != state else {
            return
        }
        switch state {
        case .loading:
            self.imageView?.alpha = 0.3
            self.gifImageView?.alpha = 0.3
            self.spinner.startAnimating()
            
        case .missingThumbnail:
            self.imageView?.alpha = 0.3
            self.gifImageView?.alpha = 0.3
            self.spinner.startAnimating()
            //TODO: load HD asset here
            let downloader = WNDownloader(maxConncurrent: 1)
            downloader.download([self.asset!.thumbnailUrl], progressHandler: { savedAssetPath, progress in
                // progress not needed
                }, completionHandler: {
                    //let reloadItem = self.asset
                    //self.asset = reloadItem
                    self.setState(.active)
            })
            
        case .missingAsset:
            self.imageView?.alpha = 0.3
            self.gifImageView?.alpha = 0.3
            self.spinner.startAnimating()
            //TODO: load HD asset here
            let downloader = WNDownloader(maxConncurrent: 1)
            downloader.download([self.asset!.assetUrl], progressHandler: { savedAssetPath, progress in
                // progress not needed
                }, completionHandler: {
                    //let reloadItem = self.asset
                    //self.asset = reloadItem
                    self.setState(.active)
            })
            
        case .active:
            self.imageView?.alpha = 1
            self.gifImageView?.alpha = 1
            self.spinner.stopAnimating()
        }
        self.state = state
    }
    
    deinit {
        print("emoji cell deinit")
        // TODO: sometimes causes crashing... added check to make sure self is not nil
        // if it contiunes, remove this line.
        if self.gifImageView?.animatedImage != nil {
            self.gifImageView?.animatedImage.clearCache()
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.setState(.active)
        self.spinner.stopAnimating()
        self.imageView?.image = nil
        self.imageView?.backgroundColor = UIColor.clear
        self.gifImageView?.animatedImage = nil
    }
    
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        //self.queue = OperationQueue()
        // Initialization code
        
        //self.layer.borderColor = UIColor.red.cgColor
        //self.layer.borderWidth = 1.0

    }
    
    open func startAnimatingIfNecessary () {
        if self.gifImageView?.animatedImage != nil {
            self.gifImageView?.startAnimating()
        }
    }

    open func stopAnimatingIfNecessary () {
        if self.gifImageView?.animatedImage != nil {
            self.gifImageView?.stopAnimating()
        }
    }
}

