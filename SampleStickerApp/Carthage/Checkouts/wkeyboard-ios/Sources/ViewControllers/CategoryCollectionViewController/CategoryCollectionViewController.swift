//
//  CategoryCollectionViewController.swift
//  WKeyboard
//
//  Created by David Hoofnagle on 1/12/17.
//  Copyright © 2017 Whalerock Industries. All rights reserved.
//

import UIKit
import WUtilities
import WAssetManager
import WAnalytics

public protocol CategoryViewControllerDelegate {
    func closeToneSelector(animated: Bool)
    func shouldScrollToCategory(_ category: WKCategory, at indexPath: IndexPath)
}

open class CategoryCollectionViewController: UICollectionViewController {

    private var isInited = false
    open var selectedIndex = 0
    open var lastSelectedCategoryIndex = 0
    open var isMidSelection = false
    open var delegate: CategoryViewControllerDelegate?
    public var type: WKType? {
        didSet {
            categories = type?.categories
        }
    }
    public var categories: [WKCategory]? {
        didSet {
            reload()
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        //need to autolayout ASAP
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.highlightCategory(at: IndexPath(row: selectedIndex, section: 0), withNotification: false)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open func reload() {
        self.collectionView?.reloadData {
            guard self.categories != nil else {
                return
            }
            if let customLayout = self.collectionView!.collectionViewLayout as? CategoryCollectionViewLayout {
                customLayout.categoryCount = CGFloat(self.categories!.count)
            }
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: UICollectionViewDataSource

    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard categories != nil else {
            return 0
        }
        print("\(categories!.count) in section")
        return categories!.count
    }

    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! CategoryCell
        cell.indexPath = indexPath
        if WKConfig.sharedInstance.wantsCategoryImagesFromCMS {
            if let cachedAsset = WAssetManager.sharedInstance.localPathForAsset(fromUrl: type!.categories![indexPath.item].assetUrl) {
                cell.iconView.image = UIImage(contentsOfFile: cachedAsset)
                if !WKConfig.sharedInstance.wantsTemplateImageForActiveCategory {
                    cell.iconView.alpha = WKConfig.sharedInstance.categoryInactiveOpacity
                }
            }
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    open override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        delegate?.closeToneSelector(animated: true)
        
        isMidSelection = true
        selectedIndex = indexPath.item
        highlightCategory(at: indexPath, withNotification: true)
        lastSelectedCategoryIndex = indexPath.row
        
        guard let categories = type?.categories else { return }
        let invertedIndexPath = IndexPath(row: 0, section: indexPath.item)
        delegate?.shouldScrollToCategory(categories[indexPath.item], at: invertedIndexPath)
    }


    open func highlightCategory(at indexPath: IndexPath, withNotification: Bool) {
        guard type != nil else {
            return
        }
        guard let categoryCount = type?.categories?.count, categoryCount > 0, indexPath.section < categoryCount else {
            return
        }
        guard let assetCount = type?.assets?.count, assetCount >= (indexPath as NSIndexPath).section && assetCount >= (indexPath as NSIndexPath).item  else {
            return
        }

        if withNotification {
            let headerNotification = HeaderViewNotification(type: .Default, text: (type?.categories![indexPath.item].title)!, autoHide: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: WKNotifications.HeaderViewDisplayStatus), object: nil, userInfo: headerNotification.userInfo())
        } else {
            lastSelectedCategoryIndex = indexPath.item
        }
        
        selectedIndex = indexPath.item
        
        //needed for category selection on initial load and on manual scrolling
        for cell in self.collectionView!.visibleCells {
            (cell as! CategoryCell).isSelectionHighlighted = false
        }
        if let cell = self.collectionView?.cellForItem(at: indexPath) {
            (cell as! CategoryCell).isSelectionHighlighted = true
        }
    }
    
}
