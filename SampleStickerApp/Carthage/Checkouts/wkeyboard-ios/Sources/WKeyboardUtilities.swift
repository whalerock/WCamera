//
//  WKeyboardUtilities.swift
//  WKeyboard
//
//  Created by aramik on 7/11/16.
//
//

import Foundation
import UIKit
import CoreImage
import WUtilities
import WAssetManager
import WNetwork
import WAnalytics

open class WKeyboardUtilities {
    
    fileprivate var loggingEnabled: Bool = true
    
    open weak var inputViewController: MainViewController?
    
    open var applicationContext: String {
        get {
            return (self.inputViewController?.parent?.value(forKey: "_hostBundleID") as? String)?.lowercased() ?? ""
        }
    }
    
    public var hasOpenAccess: Bool {
        get {
            var hasFullAccess = false
            if #available(iOS 10.0, *) {
                let originalItems = UIPasteboard.general.items
                let originalItemsCount = UIPasteboard.general.items.count
                UIPasteboard.general.addItems([["key": "value"]])
                if UIPasteboard.general.items.count > originalItemsCount {
                    UIPasteboard.general.items = originalItems
                    hasFullAccess = true
                }
            } else {
                // Fallback on earlier versions
                return UIPasteboard.general.isKind(of: UIPasteboard.self)
            }
            return hasFullAccess
        }
    }
    
    // MARK: TextDocumentProxy overrides
    
    open func insertText(text:String) {
        
        guard self.inputViewController?.textDocumentProxy != nil else {
            print("[WRIKeyboardUtils: TDProxyRef not set!")
            return
        }
        self.inputViewController?.textDocumentProxy.insertText(text)
        NotificationCenter.default.post(name: Notification.Name(rawValue: WKNotifications.TextDocumentProxyInsertText), object: nil, userInfo: ["input":text])
        //NotificationCenter.defaultCenter.postNotificationName(WKNotifications.TextDocumentProxyInsertText, object: nil, userInfo: ["input":text])
    }
    
    
    open func deleteBackwards() {
        guard self.inputViewController?.textDocumentProxy != nil else {
            print("[WRIKeyboardUtils: TDProxyRef not set!")
            return
        }
        self.inputViewController?.textDocumentProxy.deleteBackward()
        NotificationCenter.default.post(name: Notification.Name(rawValue: WKNotifications.TextDocumentProxyDeleteBackwards), object: nil, userInfo: nil)
        
    }
    
    private func assetSize(applicationContext:String) -> CGSize {
        guard
            let applicationContextSize = WKeyboard.api.config?.value(forKeyPath: "configurations.applicationContext.\(applicationContext)") as? NSDictionary,
            let definedWidth = applicationContextSize.value(forKey: "width") as? Int,
            let definedHeight = applicationContextSize.value(forKey: "height") as? Int
            else {
                return CGSize(width: 530, height: 530)
        }
        return CGSize(width: CGFloat(definedWidth), height: CGFloat(definedHeight))
    }

    private func assetSize(applicationContext:String,  assetType assetTypeId:String) -> CGSize {
        guard
            let typeName = WKeyboard.parser.getTypeById(assetTypeId)?.title?.lowercased(),
            let applicationContextSize = WKeyboard.api.config?.value(forKeyPath: "configurations.applicationContext.\(applicationContext)") as? NSDictionary,
            let definedWidth = applicationContextSize.value(forKeyPath: "\(typeName).width") as? Int,
            let definedHeight = applicationContextSize.value(forKeyPath: "\(typeName).height") as? Int
            else {
                return assetSize(applicationContext: applicationContext)
        }
        return CGSize(width: CGFloat(definedWidth), height: CGFloat(definedHeight))
    }
    

    private func imageAssetResize(image:UIImage, newSize:CGSize)-> UIImage {
        //        let newHeight = newSize.height
        //        let scale = newHeight / image.size.height
        //        let newWidth = image.size.width * scale
        
        guard applicationContext != "com.apple.mobilesms" else {
            // If messenger application
            let rect = CGRect(x: 0, y: 0, width: newSize.width/UIScreen.main.scale, height: newSize.height/UIScreen.main.scale)
            let resizedImage = resizeToSize(image: image, newSize: newSize, scale: UIScreen.main.scale)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width/UIScreen.main.scale, height: newSize.height/UIScreen.main.scale), true, UIScreen.main.scale)
            UIGraphicsGetCurrentContext()
            UIColor.white.setFill()
            UIRectFill(rect)
            resizedImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width/UIScreen.main.scale, height: newSize.height/UIScreen.main.scale))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
//            return resizeToSize(image: image, newSize: newSize, scale: 1.0)
//            return resizeToSize(image: image, newSize: newSize, scale: UIScreen.main.scale)
        }
        // All other apps
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), true, 1.0)
        UIGraphicsGetCurrentContext()
        UIColor.white.setFill()
        UIRectFill(rect)
        // Logic to add white bars to sides of image in twitter
        image.draw(in: CGRect(x: (newSize.width / 2) - (newSize.height / 2), y: 0, width: newSize.height, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    public func clearPasteboardForAllTypes() {
        UIPasteboard.general.setValue("", forPasteboardType: "com.compuserve.gif")
        UIPasteboard.general.setValue("", forPasteboardType: "public.png")
    }

    public func resizeAsset(asset:WKAsset, forApplicationContext applicationContext:String) -> UIImage? {
        if let localPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: asset.assetUrl) {
            if let uiImage = UIImage(contentsOfFile: localPath) {
                let imageSize = assetSize(applicationContext: applicationContext, assetType: asset.type)
                // Not sure why the distinction here ?? twitter resize specific logic?
                guard applicationContext != "com.apple.mobilesms" else {
                    return resizeToSize(image: uiImage, newSize: imageSize, scale: 1.0)
                }

                let pasteImage = UIImage(data: UIImagePNGRepresentation(uiImage)!)
                return imageAssetResize(image: pasteImage!, newSize: imageSize)
            }
        }
        return nil
    }
    
    public func copyImageToClipboard(asset: String, assetID: String, errorHandler:(()->Void)?, assetRef: WKAsset? = nil, completionHandler:(()->Void)?) {
        
        print("copy image to clipboard:")
        print("config: \(WKeyboard.api.config)")

        let resizeBlock = { (cachedAsset: String) in
            if let imageData = NSData(contentsOfFile: cachedAsset) {

                if cachedAsset.contains(".gif") {
                    UIPasteboard.general.setData(imageData as Data, forPasteboardType: "com.compuserve.gif")
                } else if cachedAsset.contains(".amr") {
                    let amrDict = NSMutableDictionary(capacity: 3)
                    amrDict.setValue("Audio Message.amr", forKey: "public.url-name")
                    amrDict.setValue("Audio Message.amr", forKey: "public.utf8-plain-text")
                    amrDict.setValue(imageData, forKey: "org.3gpp.adaptive-multi-rate-audio")

                    UIPasteboard.general.items =  NSArray(object: amrDict) as! [[String: Any]]
                } else if cachedAsset.contains(".mp4") {
                    UIPasteboard.general.setData(imageData as Data, forPasteboardType: "public.mpeg-4")
                } else {
                    //config value for sticker size
                    //resize to desired dimensions
                    var imageSize:CGSize
                    if assetRef != nil {
                        imageSize = self.assetSize(applicationContext: self.applicationContext, assetType: assetRef!.type)
                    } else {
                        imageSize = self.assetSize(applicationContext: self.applicationContext)
                    }
                    let pasteImage = UIImage(data: imageData as Data)
                    let newImage = self.imageAssetResize(image: pasteImage!, newSize: imageSize)
                    if let resizedData = UIImagePNGRepresentation(newImage) {
                        UIPasteboard.general.setData(resizedData, forPasteboardType: "public.png")
                    }
                }
                
                WAnalytics.manager.sendEvent(.keyboard, action: .copied, label: "\(asset)", contentId: assetID, contentCategory: WKManager.sharedInstance.getCategoryTitle(assetRef?.category), contentType: WKManager.sharedInstance.getTypeTitle(assetRef?.type), contentName: assetRef?.title)

                DispatchQueue.main.async {
                    completionHandler?()
                }
            }
        }
        
        if let cachedAsset = WAssetManager.sharedInstance.localPathForAsset(fromUrl: asset) {
            resizeBlock(cachedAsset)
        } else {
            let downloader = WNDownloader(maxConncurrent: 1)
            downloader.download([asset], progressHandler: { savedAssetPath, _ in

                guard savedAssetPath != nil else {
                    return
                }

                print("download complete")
                
                if let localAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: savedAssetPath!) {

                    DispatchQueue.global().async {
                        resizeBlock(localAssetPath)
                    }
                }
            }, completionHandler: {
                print("downloader Completion")
            })
        }
    }
    
    private func resizeToSize (image: UIImage, newSize: CGSize, scale: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale);
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    public func replaceLastWordWith(text:String) {
        guard text.characters.count > 0 else {
            return
        }
        for _ in 0...text.characters.count - 1 {
            self.inputViewController?.textDocumentProxy.deleteBackward()
        }
        self.inputViewController?.textDocumentProxy.insertText(text)
    }
}

public extension UIInputViewController {
    
    
    public func openURL(_ url: URL) -> Bool {
        do {
            let application = try self.sharedApplication()
            return (application.perform(#selector(UIInputViewController.openURL(_:)), with: url) != nil)
        }
        catch {
            print("error")
            return false
        }
    }
    
    func sharedApplication() throws -> UIApplication {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            
            responder = responder?.next
        }
        
        throw NSError(domain: "com.whalerock.wkutilities", code: 1, userInfo: nil)
    }
}


public func mainStoryboard() -> UIStoryboard {
    let frameworkBundle = Bundle(identifier: "whalerock.WKeyboard")
    let storyboard = UIStoryboard(name: "Keyboard", bundle: frameworkBundle)
    return storyboard
}


public extension UICollectionView {
    func reloadData(completion: @escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
        { _ in completion() }
    }
}


public extension Collection {
    func last(count:Int) -> [Self.Iterator.Element] {
        let selfCount = self.count as! Int
        if selfCount <= count - 1 {
            return Array(self)
        } else {
            return Array(self.reversed()[0...count - 1].reversed())
        }
    }
}
