//
//  WKNetowrkAPIParser.swift
//  Kimoji
//
//  Created by aramik on 6/15/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WUtilities
import WNetwork
import WAssetManager
import WStoreKit


open class WKNetowrkAPIParser {


    fileprivate var loggingEnabled: Bool = true

    fileprivate var assetsToDownload: [String]!
    let parseGroup = DispatchGroup()

    public typealias WKNetworkAPIParserBlock = (_ types:[WKType]?,
        _ packs:[WKPack]?,
        _ categories:[WKCategory]?,
        _ assets:[String]?)->()
    
    public var storedPacks: [WKPack]?
    public var storedTypes: [WKType]?
    public var storedCategories: [WKCategory]?
    public var storedAssets: [WKAsset]?

    public init() {
        self.assetsToDownload = [String]()
        WStoreKit.manager.autoConfigure()
    }

    open func addToAssetQueue(_ url:String) {
        guard self.assetsToDownload != nil else {
            return
        }

        guard url != "" else { return }

        guard WAssetManager.sharedInstance.localPathForAsset(fromUrl: url) == nil else {
            return
        }

        if !self.assetsToDownload.contains(url) {
            self.assetsToDownload.append(url)
        }

    }

    open func getTypes() -> [WKType]? {

        if let types = WKeyboard.api.config?.value(forKeyPath: "types") as? [[String: Any]] {
            var typesArray = [WKType]()
            self.parseGroup.enter()
            
            outer: for i in 0..<types.count {
                let type = types[i]
                
                if WKConfig.sharedInstance.isImessageExtension {
                    if let ignoreTypeTitles = WKeyboard.api.config?.value(forKeyPath: "configurations.ignore_types_imessage") as? [String] {
                        inner: for title in ignoreTypeTitles {
                            if title == type["title"] as? String {
                                continue outer
                            }
                        }
                    }
                }
                
                if let wkType = WKType(json: type as NSDictionary) {
                    typesArray.append(wkType)
                    self.addToAssetQueue(wkType.assetUrl!)
                }
            }
            
            typesArray.sort { $0.position! < $1.position! }
            self.parseGroup.leave()
            return typesArray
        }

        return nil
    }

    open func getPacks() -> [WKPack]? {

        if let packs = WKeyboard.api.config?.value(forKeyPath: "packs") as? NSArray {
            var packsArray = [WKPack]()
            self.parseGroup.enter()
            for pack in packs {
                if let wkPack = WKPack(json: pack as? NSDictionary) {
                    packsArray.append(wkPack)
                    self.addToAssetQueue(wkPack.assetUrl)

                }
            }
            packsArray.sort { $0.position < $1.position }
            self.parseGroup.leave()
            return packsArray
        }

        return nil
    }

    open func getCategories() -> [WKCategory]? {

        if let categories = WKeyboard.api.config?.value(forKeyPath: "categories") as? NSArray {
            var categoriesArray = [WKCategory]()
            self.parseGroup.enter()
            for category in categories {
                if let wkCategory = WKCategory(json: category as? NSDictionary) {
                    categoriesArray.append(wkCategory)
                    self.addToAssetQueue(wkCategory.assetUrl)
                   
                }
            }
            categoriesArray.sort { $0.position < $1.position }
            self.parseGroup.leave()
            return categoriesArray
        }

        return nil
    }

    open func getAssets() -> [WKAsset]? {

        guard let config = WKeyboard.api.config?.value(forKey: "configurations") as? NSDictionary else {
            print("config not found")
            return nil
        }


        // Determine if under review
        var underReview = false
//        var testVersion: String?
//        testVersion = "4.0.1"
//        testVersion, //
        if let approvedVersion = config.value(forKeyPath: "approved_version") as? String,
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        {
            // If current version is more recent than the latest approved version
            if currentVersion.compare(approvedVersion, options: NSString.CompareOptions.numeric) == ComparisonResult.orderedDescending {
                underReview = true
            }
        }

        let wantsThumbs = WKConfig.sharedInstance.wantsThumbnailsForCell
        
        if let assets = WKeyboard.api.assetsConfig?.value(forKey: "assets") as? NSArray {
            WKManager.sharedInstance.keywordAssets.removeAll()
            var assetsArray = [WKAsset]()
            self.parseGroup.enter()
            for asset in assets {
                if let wkAsset = WKAsset(json: asset as? NSDictionary) {
                    // Verify not an explicit asset while underReview
                    if wkAsset.explicit && underReview {
                        continue
                    }

                    if let bundle = self.getPackById(wkAsset.pack)?.bundleIdentifier {
                        if bundle == "ios_default_pack" || WStoreKit.manager.didPurchase(bundle) {

                            // Add tones to downloader, if available.
                            for tone in wkAsset.tones! {
                                if (wantsThumbs) {
                                    self.addToAssetQueue(tone.thumbnailUrl)
                                } else {
                                    self.addToAssetQueue(tone.assetUrl)
                                }
                            }

                            if wkAsset.keywords.count > 0 {
                                WKManager.sharedInstance.keywordAssets.append(wkAsset)
                            }
                            
                            assetsArray.append(wkAsset)
                            if (wantsThumbs) {
                                self.addToAssetQueue(wkAsset.thumbnailUrl)
                            } else {
                                self.addToAssetQueue(wkAsset.assetUrl)
                            }
                        }
                    }

                }
            }

            assetsArray.sort { $0.position < $1.position }
            self.parseGroup.leave()
            return assetsArray
        }

        return nil
    }

    open func getPackById(_ id:String) -> WKPack? {
        return self.storedPacks?.first(where: {  $0.id == id })
    }
    
    public func getTypeById(_ id:String) -> WKType? {
        return self.storedTypes?.first(where: {  $0.id == id })
    }
    
    public func getCategoryById(_ id:String) -> WKCategory? {
        return self.storedCategories?.first(where: {  $0.id == id })
    }


    open func parse(completionHandler:@escaping WKNetworkAPIParserBlock) {

        print("parsing, \(Date())")
        
        storedTypes = self.getTypes()
        storedPacks = self.getPacks()
        storedCategories = self.getCategories()
        storedAssets = self.getAssets()
        
        //self.parseGroup.notify(queue: DispatchQueue.main) {

            if self.storedTypes != nil && self.storedCategories != nil  && self.storedAssets != nil && self.storedPacks != nil {

                for i in 0..<self.storedTypes!.count {
                    self.storedTypes![i].categories?.removeAll()
                    self.storedTypes![i].assets?.removeAll()

                    for j in 0..<self.storedCategories!.count {
                        var _assetsInCategory = [WKAsset]()
                        for k in 0..<self.storedAssets!.count {
                            if self.storedAssets![k].category == self.storedCategories![j].id && self.storedAssets![k].type == self.storedTypes![i].id {
                                _assetsInCategory.append(self.storedAssets![k])
                            }
                        }
                        if !_assetsInCategory.isEmpty {
                            self.storedTypes![i].categories?.append(self.storedCategories![j])
                            self.storedTypes![i].assets?.append(_assetsInCategory)
                        }
                    }
                }


                self.assetsToDownload.forEach { asset in
                    if WAssetManager.sharedInstance.localPathForAsset(fromUrl: asset) != nil {
                        if let index = self.assetsToDownload.index(of: asset) {
                            self.assetsToDownload.remove(at: index)
                        }
                    }
                }

                print("doneparsing, \(Date())")
                
                // clean up empty categories
                //(GlobalMainQueue).async {
                    WKManager.sharedInstance.types = self.storedTypes
                    WKManager.sharedInstance.categories = self.storedCategories
                    print("calling completionHandler: \(completionHandler)")
                    completionHandler(self.storedTypes!, self.storedPacks!, self.storedCategories!, self.assetsToDownload)
                //}
                
            } else {
                //we don't have a manifest yet
                completionHandler(nil, nil, nil, nil)
            }
        //}
    }
    
    public func pruneAsset(withURL: String) {
        print("should Prune: \(withURL)")
        
        for k in 0..<storedAssets!.count {
            let asset = self.storedAssets![k]
            if asset.assetUrl == withURL || asset.thumbnailUrl == withURL {
                print("found asset!")
                self.storedAssets?.remove(at: k)
                print("storedAssets count: \(storedAssets?.count)")
                break
            }
        }
        
        //modify the storedTypes [[WKAsset]] to remove this asset by url
        for i in 0..<storedTypes!.count {
            let storedType = self.storedTypes![i]
            for j in 0..<storedType.assets!.count {
                var assetsArray = storedType.assets![j]
                for k in 0..<assetsArray.count {
                    if assetsArray[k].assetUrl == withURL || assetsArray[k].thumbnailUrl == withURL {
                        self.storedTypes![i].assets![j].remove(at: k)
                        WKManager.sharedInstance.types = storedTypes
                        break
                    }
                }
            }
        }
        
    }
    
    
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
