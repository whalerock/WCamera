//
//  ToneSelectorViewController.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit
import WNetwork
import WAssetManager

public protocol ToneSelectorViewControllerDelegate {
    func shouldCloseToneSelector(animated: Bool)
}

open class ToneSelectorViewController: UIViewController {
    
    // MARK: InterfaceBuilder Outlets
    @IBOutlet weak var toneStackView: UIStackView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var toneStackViewWidthConstraint: NSLayoutConstraint!
    var delegate: ToneSelectorViewControllerDelegate?
    
    // MARK: Public Initializers
    open var asset: WKAsset!
    
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = true
    fileprivate var blurView: UIVisualEffectView!
    
    // MARK: Override Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.log(.log, message: "Loaded")
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        if asset != nil {
            loadTonesFromAsset()
        }
    }
    
    deinit {
        self.log(.log, message: "[ToneSelectorViewController]:: Deinitialized")
    }
    
    // MARK: Lifecycle
    func loadTonesFromAsset() {
        
        self.hideAllTones(false)
        
        createToneButton(asset: asset, atIndex: 0, withTag: 0)
        for i in 0..<asset.tones!.count {
            createToneButton(asset: asset, atIndex: i+1, withTag: i + 100)
        }
        //original asset not included in tones
        toneStackViewWidthConstraint.constant = (CGFloat(asset.tones!.count+1) * toneStackView.bounds.height) + (10.0*CGFloat(asset.tones!.count))
        
        showButtons(animated: true)
    }
    
    func createToneButton(asset: WKAsset, atIndex: Int, withTag tag: Int) {
        let button = UIButton()
        button.tag = tag
        button.setTitle("", for: UIControlState())
        button.backgroundColor = UIColor.clear
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(ToneSelectorViewController.didSelectTone(_:)), for: .touchUpInside)
        
        button.heightAnchor.constraint(equalToConstant: toneStackView.bounds.height).isActive = true
        button.widthAnchor.constraint(equalToConstant: toneStackView.bounds.height).isActive = true

        if atIndex > 0 {
            let toneAsset = asset.tones![atIndex-1]
            if let toneImage = WAssetManager.sharedInstance.localPathForAsset(fromUrl: toneAsset.thumbnailUrl) {
                if let thumbnailImage = UIImage(contentsOfFile: toneImage) {
                    button.setImage(thumbnailImage, for: .normal)
                }
            } else {
                let downloader = WNDownloader(maxConncurrent: 1)
                downloader.download([toneAsset.thumbnailUrl], progressHandler: { savedAssetPath, _ in
                    if let thumbnailImage = UIImage(contentsOfFile: savedAssetPath!) {
                        button.setImage(thumbnailImage, for: .normal)
                    }
                }, completionHandler: {})
            }
        } else {
            if let toneImage = WAssetManager.sharedInstance.localPathForAsset(fromUrl: asset.thumbnailUrl) {
                if let thumbnailImage = UIImage(contentsOfFile: toneImage) {
                    button.setImage(thumbnailImage, for: .normal)
                }
            } else {
                let downloader = WNDownloader(maxConncurrent: 1)
                downloader.download([asset.thumbnailUrl], progressHandler: { savedAssetPath, _ in
                    if let thumbnailImage = UIImage(contentsOfFile: savedAssetPath!) {
                        button.setImage(thumbnailImage, for: .normal)
                    }
                }, completionHandler: {})
            }
        }
        
        toneStackView.addArrangedSubview(button)
        button.frame.origin.y = 70
    }
    
    func showButtons(animated: Bool) {
        var index = 0
        for v in toneStackView.subviews {
            if v is UIButton {
                if animated {
                    UIView.animate(withDuration: 0.3,
                                   delay: TimeInterval(0.1 * Float(index) / 4),
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 1.2,
                                   options: UIViewAnimationOptions(),
                                   animations: {
                                    
                                    v.frame.origin.y = 0
                                    
                    }, completion: {_ in
                                    
                    })
                    index += 1
                }
            }
        }

    }
    
    open override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        switch toInterfaceOrientation {
        case .landscapeLeft, .landscapeRight:
            self.label.isHidden = true
        default:
            self.label.isHidden = false
        }
    }
    
    fileprivate func hideAllTones(_ animated:Bool, completion:(()->())? = nil) {
//        var animationIndex = 0
//        for (index, constraint) in toneYLayoutConstraint.enumerated().reversed() {
//            constraint.constant = 100
//            if animated {
//                UIView.animate(withDuration: 0.3,
//                                           delay: TimeInterval(0.2 * Float(animationIndex) / 4),
//                                           usingSpringWithDamping: 0.5,
//                                           initialSpringVelocity: 1.2,
//                                           options: UIViewAnimationOptions(),
//                                           animations: {
//                                            self.view.layoutIfNeeded()
//                                            self.getButtonAtIndex(index)?.alpha = 0
//                    },
//                                           completion: {_ in
//                                            completion?()
//                })
//            } else {
//                self.getButtonAtIndex(index)?.alpha = 0
//            }
//            animationIndex += 1
//        }
    }
    
    open func showAllTones(_ animated:Bool) {
//        for (index, constraint) in toneYLayoutConstraint.enumerated() {
//            constraint.constant = 0
//            if animated {
//                UIView.animate(withDuration: 0.3,
//                                           delay: TimeInterval(0.1 * Float(index) / 4),
//                                           usingSpringWithDamping: 0.5,
//                                           initialSpringVelocity: 1.2,
//                                           options: UIViewAnimationOptions(),
//                                           animations: {
//                                            self.view.layoutIfNeeded()
//                                            self.getButtonAtIndex(index)?.alpha = 1
//                    },
//                                           completion: {_ in
//                                            
//                })
//            }
//            
//        }
    }
    
    
    fileprivate func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    open func close(_ animated:Bool = true) {
        if animated {
            self.hideAllTones(true) {
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            }
        } else {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.shouldCloseToneSelector(animated: false)
    }
    
    func didSelectTone(_ sender: UIButton) {
        print("selected \(sender.tag)")
        
        var tone: String = asset.assetUrl
        var toneId: String = asset.id
        if sender.tag >= 100 {
            let toneAsset = asset.tones![sender.tag - 100]
            tone = toneAsset.assetUrl
            toneId = toneAsset.id
        }
        
        self.spinner.frame = sender.frame
        self.spinner.startAnimating()
        sender.alpha = 0.3
        
        WKeyboard.utils.copyImageToClipboard(asset: tone, assetID: toneId, errorHandler: nil, assetRef: asset) {
            sender.alpha = 1.0
            self.spinner.stopAnimating()
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: WKNotifications.HeaderViewCopiedNotification), object: nil)
            self.delegate?.shouldCloseToneSelector(animated: true)
        }
    
    }
    
    // MARK: Layouts
    
    // MARK: User Interactions
    
    // MARK: Additional Helpers
    /**
     WRI custom logger which provides ability to enable/disable logging per class basis. Makes for cleaner debug console when needed.
     - parameter type:    See WRILoggerType
     - parameter message: Message you want to log
     */
    fileprivate func log(_ type: WRILoggerType, message:String) {
        guard self.loggingEnabled else {
            return
        }
        WRILogger.log(#file, type: type, message: message)
    }
}
