//
//  ViewController.swift
//  ExampleApplication
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import UIKit
import AVFoundation
import WCamera

import WKeyboard
import WNetwork
import WAssetManager

class ViewController: UIViewController {
    
//    weak var delegate: WCameraDelegate?
//
//    var captureSession: AVCaptureSession!
//    var isSessionRunning: Bool!
//    var currentSettings: WCameraSettings!
//    var videoDevice: AVCaptureDevice!
//    var videoDeviceInput: AVCaptureDeviceInput!
//    var audioDevice: AVCaptureDevice!
//    var audioDeviceInput: AVCaptureDeviceInput!
//    var photoOutput: AVCapturePhotoOutput!
//    
//    var previewView: UIView!
//    var previewLayer: AVCaptureVideoPreviewLayer!
//    
//    var captureVideoDataOutput: AVCaptureVideoDataOutput!
//    var movieOutput: AVCaptureMovieFileOutput!
//    
//    var cameraDirection: WCameraDirection!
    
    var imageEditorViewController: ImageEditorViewController?
    
    var isParsing = false
    var downloader: WNDownloader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WCamera.shared.delegate = self
        let cameraSettings = WCameraSettings.init(quality: AVCaptureSessionPresetHigh, type: WCameraCaptureType.video, direction: WCameraDirection.front)
       
        WCamera.shared.start(cameraUsing: cameraSettings)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            let orient = UIApplication.shared.statusBarOrientation
            WCamera.shared.fixRotation(forOrientation: orient)
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            print("rotation completed")
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    @IBAction func takePic(sender: UIButton) {
        WCamera.shared.capturePhoto()
    }
    
    @IBAction func swapCameraPosition(sender: UIButton) {
        WCamera.shared.switchCameraPosition()
    }

}

extension ViewController: WCameraDelegate {
   
    func wCameraDidFinishInitializing() {
        WCamera.shared.previewLayer.frame = self.view.frame
        WCamera.shared.previewView.frame.size.height -= 80
        self.view.insertSubview(WCamera.shared.previewView, at: 0)
    }
    
    func didCapture(image: UIImage) {
        imageEditorViewController?.view.removeFromSuperview()
        imageEditorViewController?.removeFromParentViewController()
        imageEditorViewController = nil
        
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageEditorViewController") as?ImageEditorViewController {
            WCamera.shared.pauseSession()
            imageEditorViewController = vc
            imageEditorViewController!.delegate = self
            self.addChildViewController(imageEditorViewController!)
            self.view.addSubview(imageEditorViewController!.view)
            imageEditorViewController!.view.frame = self.view.bounds
            imageEditorViewController!.backgroundImageView.image = image
        }
    }
    
}

extension ViewController: ImageEditorViewControllerDelegate {
 
    func viewControllerForAssetInput(completion: @escaping ((UIViewController?)->Void)) {
        //replace with other protocol oriented data source
        if let emojiCollectionViewController = self.storyboard?.instantiateViewController(withIdentifier: "sb_EmojiCollectionViewController") as? EmojiCollectionViewController {
            if let api = Config.sharedInstance().get("wri.endpoint") as? String {
                WKConfig.sharedInstance.api = api
                WKeyboard.api.fetchPayload { payload in
                    self.loadWKAssets() { assetURLs, error in
                        //let assets = WKeyboard.parser.getAssets()
                        
                        let type = WKManager.sharedInstance.types?[1]
                        print(type?.title)
                        emojiCollectionViewController.type = type
                        emojiCollectionViewController.numberOfRows = 3
                        emojiCollectionViewController.delegate = self
                        
                        emojiCollectionViewController.view.backgroundColor = .red
                        emojiCollectionViewController.reload()
                        completion(emojiCollectionViewController)
                    }
                }
            }
        }
    }
    
    func didCancel() {
        guard imageEditorViewController != nil else {
            print("ViewController.ImageEditorViewControllerDelegate.didCancel:: imageEditorViewController is nil")
            return
        }
        imageEditorViewController?.view.removeFromSuperview()
        imageEditorViewController?.removeFromParentViewController()
        imageEditorViewController = nil
        WCamera.shared.resumeSession()
    }
    
    func loadWKAssets(completion:@escaping (([String]?, Error?)->Void)) {
        WKeyboard.parser.parse { types, packs, categories, assetURLs in
            guard types != nil, packs != nil, categories != nil, assetURLs != nil else {
                self.isParsing = false
                return
            }
            self.isParsing = true
            self.downloadAssets(types!, packs!, categories!, assetURLs!, completion: completion)
        }
    }
  
    func downloadAssets(_ types: [WKType], _ packs: [WKPack], _ categories: [WKCategory], _ assetURLs: [String], completion:@escaping (([String]?, Error?)->Void)) {
        if assetURLs.count > 0 {
            if !WNetwork.manager.hasConnection() {
//                self.setState(.connectionRequired, animated: false)
                return
            }
//            self.setState(.downloadingContent, animated: true)
            
            self.downloader = WNDownloader(maxConncurrent: 5000)
            self.downloader?.download(assetURLs, progressHandler: { savedAssetPath, progress in
                if let assetPath = savedAssetPath {
                    if let localAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: assetPath) {
//                        if self.downloadViewController != nil {
                            if !localAssetPath.contains("gif") && !localAssetPath.contains("apng") {
                                if let imgData = try? Data(contentsOf: URL(fileURLWithPath: localAssetPath)) {
                                    if let img = UIImage(data: imgData) {
                                        DispatchQueue.main.async {
//                                            self.downloadViewController?.slowConnectionTimer?.invalidate()
//                                            self.downloadViewController?.statusLabel.text = ""
//                                            self.downloadViewController?.assetPreview?.image = nil
//                                            self.downloadViewController?.assetPreview?.image = img
//                                            self.downloadViewController?.progressView?.progress = Float(progress)
                                            print(Float(progress))
                                        }
                                    }
                                }
                            }
//                        }
                    }
                    
                }
            }, completionHandler: {
                self.isParsing = false
                completion(assetURLs, nil)
            })
        } else {
            self.isParsing = false
            completion(assetURLs, nil)
        }
    }
    
}

extension ViewController: EmojiCollectionViewControllerDelegate {
    
    func didSelectItem(at indexPath: IndexPath) {
        
    }
    
    func categoryViewRef() -> CategoryCollectionViewController? {
        return nil
    }
    
    func shouldHighlightCategory(at indexPath: IndexPath, withNotification: Bool) {
        
    }
    
    func shouldShowCategoryCollectionView(ofType type: WKType, animated: Bool) {
        
    }
    
    func shouldHideCategoryCollectionView(animated: Bool) {
        
    }
    
    func shouldOpenToneSelector(_ asset: WKAsset) {
        
    }

    func closeToneSelector(animated: Bool) {
        
    }
    
}
