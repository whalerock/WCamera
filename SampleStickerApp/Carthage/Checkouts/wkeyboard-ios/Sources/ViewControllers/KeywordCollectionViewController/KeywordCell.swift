//
//  KeywordCell.swift
//  Kimoji
//
//  Created by aramik on 4/26/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WUtilities
import WAssetManager
import WNetwork

open class KeywordCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var previewWord: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    open var asset: WKAsset? {
        didSet {
            guard self.asset != nil else { return }
            self.setImageWithURL(self.asset!.thumbnailUrl)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.spinner.stopAnimating()
        self.previewImage.image = nil
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    open func setImageWithURL(_ url:String) {
        
        if let assetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: url) {
            self.previewImage.image = UIImage(contentsOfFile: assetPath)
        } else {
            self.spinner.startAnimating()
            let downloader = WNDownloader(maxConncurrent: 1)
            downloader.download([url], progressHandler: { savedAsset, progress in
                // no progress needed
            }, completionHandler: {
                if let assetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: url) {
                    self.previewImage.image = UIImage(contentsOfFile: assetPath)
                    self.spinner.stopAnimating()
                }
            })
            
        }
    }
    
    open func startSpinner() {
        self.spinner.startAnimating()
        self.previewImage.alpha = 0.3
    }
    
    open func stopSpinner() {
        self.spinner.stopAnimating()
        self.previewImage.alpha = 1.0
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
}
