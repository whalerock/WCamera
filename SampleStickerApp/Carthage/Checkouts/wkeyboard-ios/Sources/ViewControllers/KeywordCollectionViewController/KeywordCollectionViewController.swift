//
//  KeywordCollectionViewController.swift
//  WKeyboard
//
//  Created by David Hoofnagle on 1/12/17.
//  Copyright © 2017 Whalerock Industries. All rights reserved.
//

import UIKit
import WAnalytics

open class KeywordCollectionViewController: UICollectionViewController {

    var assets = [WKAsset]()
    open var userDefinedWord: String = "" {
        didSet {
            print("userdefinedWord:", self.userDefinedWord)
            if let keys = self.getAssetsWithMatchingKeywords(self.userDefinedWord) {
                assets = keys
            }
            self.collectionView?.reloadData()
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.showsHorizontalScrollIndicator = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.insertText(_:)), name: NSNotification.Name(rawValue: WKNotifications.TextDocumentProxyInsertText), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteBackwards(_:)), name: NSNotification.Name(rawValue: WKNotifications.TextDocumentProxyDeleteBackwards), object: nil)
        
        userDefinedWord = ""
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("[KeywordCollectionViewController]: Deinitialized")
        NotificationCenter.default.removeObserver(self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! KeywordCell
        // TODO: insert image
        cell.asset = assets[(indexPath as NSIndexPath).item]
        return cell
    }

    // MARK: UICollectionViewDelegate

    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? KeywordCell {
            
            //_ = self.getAssetsWithMatchingKeywords(self.userDefinedWord.lowercased())
            selectedCell.startSpinner()
            WKeyboard.utils.copyImageToClipboard(asset: selectedCell.asset!.assetUrl, assetID: selectedCell.asset!.id, errorHandler: nil, assetRef: selectedCell.asset!) {
                
                DispatchQueue.main.async {
                    selectedCell.stopSpinner()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: WKNotifications.HeaderViewCopiedNotification), object: nil)
                }
            }
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    open func getAssetsWithMatchingKeywords(_ word:String) -> [WKAsset]? {
        var allKeywordAssets = [WKAsset]()
        var keywordAssets = [WKAsset]()
        if let types = WKManager.sharedInstance.types {
            for type in types {
                for assets in type.assets! {
                    for asset in assets {
                        for keyword in asset.keywords {
                            if !allKeywordAssets.contains(where: { $0.thumbnailUrl == asset.thumbnailUrl }) {
                                allKeywordAssets.append(asset)
                            }
                            if (keyword as AnyObject).contains(word.lowercased()) {
                                if !keywordAssets.contains(where: { $0.thumbnailUrl == asset.thumbnailUrl }) {
                                    keywordAssets.append(asset)
                                }
                            }
                        }
                    }
                }
            }
            if keywordAssets.isEmpty {
                var ret: [WKAsset] = []
                if word.characters.count == 0 {
                    ret = allKeywordAssets
                }
                return ret
            }
            return keywordAssets
        }
        return nil
        
    }
    
    @objc open func insertText(_ sender:Notification) {
        if let text =  (sender as NSNotification).userInfo?["input"] as? String {
            if text == " " || text == "\n" || text == "\n\n" {
                self.userDefinedWord = ""
            } else {
                self.userDefinedWord += text.lowercased()
            }
        }
    }
    
    @objc open func deleteBackwards(_ sender:Notification) {
        self.userDefinedWord = String(self.userDefinedWord.characters.dropLast())
    }


}

extension KeywordCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,   sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard self.collectionView != nil else {
            return CGSize(width: self.collectionView!.bounds.height, height: self.collectionView!.bounds.height)
        }
        let numberOfAssets = assets.count
        let width = self.collectionView!.frame.width / CGFloat(numberOfAssets)
        if width > self.collectionView!.bounds.height {
            return CGSize(width: width, height: self.collectionView!.bounds.height)
        }
        return CGSize(width: UIScreen.main.bounds.width / 8, height: self.collectionView!.bounds.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}

