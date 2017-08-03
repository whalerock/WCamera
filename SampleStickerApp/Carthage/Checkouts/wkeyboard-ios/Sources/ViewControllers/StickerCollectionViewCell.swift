//
//  StickerCollectionViewCell.swift
//  ellenmoji
//
//  Created by David Hoofnagle on 9/6/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import UIKit
import WAssetManager
import WAnalytics
import WUtilities
import ImageIO
import Messages
import WKeyboard

public protocol StickerCollectionViewCellDelegate: class {
    func didTapCell(asset: WKAsset)
}

@available(iOSApplicationExtension 10.0, *)
open class StickerCollectionViewCell: UICollectionViewCell {
    
    var stickerView: MSStickerView?
    var assetCanAnimate = false
    weak public var delegate: StickerCollectionViewCellDelegate?
    
    public var asset: WKAsset? {
        didSet {
            initStickerView()

            if let localPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: asset!.assetUrl) {
                stickerView?.frame = self.bounds
                let imageFileURL = URL(fileURLWithPath: localPath)
                stickerView?.sticker = try? MSSticker(contentsOfFileURL: imageFileURL, localizedDescription: "")
              
                let localAssetCFURL = imageFileURL as CFURL
                if let stickerImageSource = CGImageSourceCreateWithURL(localAssetCFURL, nil) {
                    let stickerImageFrameCount = CGImageSourceGetCount(stickerImageSource)
                    assetCanAnimate = stickerImageFrameCount > 1
                } else {
                    assetCanAnimate = false
                }
            }
        }
    }

    private func initStickerView() {
        if (stickerView == nil) {
            stickerView = MSStickerView(frame: self.bounds)
            self.addSubview(stickerView!)

            let tap = UITapGestureRecognizer(target: self, action: #selector(StickerCollectionViewCell.didTap(_:)))
            tap.numberOfTapsRequired = 1
            tap.delegate = self
            stickerView!.addGestureRecognizer(tap)
        }
    }

    func didTap (_ rec: UITapGestureRecognizer) {
        if asset?.assetUrl != nil {
            print("copied: \(asset!.assetUrl!)")
            delegate?.didTapCell(asset: asset!)
            
            let type = WKeyboard.parser.getTypeById(asset!.type)
            let category = WKeyboard.parser.getCategoryById(asset!.category)
            guard let typeTitle = type?.title, let categoryTitle = category?.title else {
                print("asset.type or asset.category does not have a title.")
                return
            }
            WAnalytics.manager.sendEvent(.messages, action: .copied, label: asset!.assetUrl!, contentId: asset!.id, contentCategory: categoryTitle, contentType: typeTitle, contentName: asset!.title)
        }
    }
    
    public func startAnimatingIfAnimatable () {
        if stickerCanAnimate() {
            stickerView?.startAnimating()
        }
    }
    
    public func stopAnimatingIfAnimatable () {
        if stickerCanAnimate() {
            stickerView?.stopAnimating()
        }
    }
    
    public func stickerCanAnimate () -> Bool {
        return assetCanAnimate
    }

}

extension UICollectionViewCell: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
