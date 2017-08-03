//
//  EmojiCollectionViewController.swift
//  WKeyboard
//
//  Created by David Hoofnagle on 1/12/17.
//  Copyright © 2017 Whalerock Industries. All rights reserved.
//

import UIKit
import WUtilities
import WAnalytics

public protocol EmojiCollectionViewControllerDelegate: class {
    func shouldOpenToneSelector(_ asset:WKAsset)
    func closeToneSelector(animated:Bool)
    func shouldShowCategoryCollectionView(ofType type: WKType, animated: Bool)
    func shouldHideCategoryCollectionView(animated: Bool)
    func shouldHighlightCategory(at indexPath: IndexPath, withNotification: Bool)
    func categoryViewRef() -> CategoryCollectionViewController?
    func didSelectItem(at indexPath: IndexPath)
}

open class EmojiCollectionViewController: UICollectionViewController {

    public var numberOfRows: CGFloat = 2
    open weak var delegate: EmojiCollectionViewControllerDelegate?
    
    open var selectedIndex: Int {
        get { return WKManager.sharedInstance.selectedIndex }
    }
    
    open var type: WKType! {
        didSet {
            if type != nil {
                self.delegate?.closeToneSelector(animated: false)
                self.collectionView?.visibleCells.forEach({ (cell) in
                    cell.prepareForReuse()
                })
                self.collectionView?.reloadData {
                    self.collectionView?.collectionViewLayout.invalidateLayout()
                    if self.type.title?.lowercased() == "gif" {
                        self.delegate?.shouldHideCategoryCollectionView(animated: false)
                    } else {
                        self.delegate?.shouldShowCategoryCollectionView(ofType: self.type!, animated: false)
                    }
                }
            }
        }
    }
    
    open var assets: [WKAsset]!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open func reload(_ completion:(()->Void)? = nil) {
        print("reload called")
        self.collectionView?.collectionViewLayout.invalidateLayout()
        self.collectionView?.reloadData {
            self.delegate?.closeToneSelector(animated: false)
            completion?()
        }
    }
    
    fileprivate func setHighlightCategory(withNotification: Bool) {
        if let firstVisbleCell = self.collectionView?.visibleCells.first {
            if let indexPath = self.collectionView?.indexPathForItem(at: firstVisbleCell.frame.origin) {
                var categoryIndexPath = IndexPath(item: (indexPath as NSIndexPath).section, section: 0)
                categoryIndexPath = IndexPath(item: 0, section: 0)
                self.delegate?.shouldHighlightCategory(at: categoryIndexPath, withNotification: withNotification)
            }
        }
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

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let assets = type?.assets else {
            return 0
        }
        return assets.count
    }
    
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let assets = type?.assets else {
            return 0
        }
        return assets[section].count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = type?.assets?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).item]
        
        if (asset?.assetUrl.contains(".gif"))! {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GIFCell", for: indexPath) as! EmojiCellView
            cell.asset = asset
            cell.adjustFrame()
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as! EmojiCellView
            cell.asset = asset
            cell.adjustFrame()
            
            return cell
        }
        
    }


    // MARK: UICollectionViewDelegate

    open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? EmojiCellView {
            if cell.imageView?.image == nil && cell.gifImageView?.image == nil {
                let asset = type?.assets?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).item]
                cell.asset = asset
                cell.adjustFrame()
            }
            cell.startAnimatingIfNecessary()
        }
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? EmojiCellView {
            cell.stopAnimatingIfNecessary()
            cell.prepareForReuse()
        }
        
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? EmojiCellView {
            if let selectedAsset = selectedCell.asset {
                //print(selectedAsset.title, selectedAsset.hasTones, selectedAsset.tones?.count)
                if selectedAsset.hasTones {
                    self.delegate?.shouldOpenToneSelector(selectedAsset)
                } else {
                    if !WKConfig.sharedInstance.isContainerApp && !WKConfig.sharedInstance.isImessageExtension {
                        selectedCell.setState(EmojiCellViewState.loading)
                        WKeyboard.utils.copyImageToClipboard(asset: selectedAsset.assetUrl, assetID: selectedAsset.id, errorHandler: nil, assetRef: selectedAsset) {
                            selectedCell.setState(EmojiCellViewState.active)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: WKNotifications.HeaderViewCopiedNotification), object: nil)
                        }
                    }
                }
            }
        }
        delegate?.didSelectItem(at: indexPath)
    }
    
    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        self.delegate?.closeToneSelector(animated: false)
        
        //let middlePoint = CGPoint(x: scrollView.contentOffset.x + (UIScreen.main.bounds.width / 2), y: 50)
        
        if let categoryCollectionViewControllerRef = delegate?.categoryViewRef() {
            if let closestIndexPath = self.indexPathForClosestToMiddle() {
                if categoryCollectionViewControllerRef.selectedIndex != (closestIndexPath as NSIndexPath).section {
                    let categoryIndexPath = IndexPath(item: (closestIndexPath as NSIndexPath).section, section: 0)
                    
                    if !categoryCollectionViewControllerRef.isMidSelection {
                        if let categoryColor = type?.categories![categoryIndexPath.item].color {
                            self.collectionView?.backgroundColor = UIColor(hex: categoryColor)
                        }
                        categoryCollectionViewControllerRef.highlightCategory(at: categoryIndexPath, withNotification: true)
                        categoryCollectionViewControllerRef.lastSelectedCategoryIndex = categoryCollectionViewControllerRef.selectedIndex
                        categoryCollectionViewControllerRef.collectionView?.scrollToItem(at: categoryIndexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
        
    }
    
    open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let categoryCollectionViewControllerRef = delegate?.categoryViewRef() {
            categoryCollectionViewControllerRef.isMidSelection = false
        }
    }
    
    open override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let categoryCollectionViewControllerRef = delegate?.categoryViewRef() {
            categoryCollectionViewControllerRef.isMidSelection = false
        }
    }
    
    fileprivate func indexPathForClosestToMiddle() -> IndexPath? {
        guard let visibleCellCount = self.collectionView?.visibleCells.count,
            visibleCellCount > 0 else {
            return nil
        }
        
        var closestCell : UICollectionViewCell = self.collectionView!.visibleCells[0];
        for cell in (self.collectionView!.visibleCells as! [EmojiCellView]) {
            let closestCellDelta = abs(closestCell.center.x - UIScreen.main.bounds.width/2 - self.collectionView!.contentOffset.x)
            let cellDelta = abs(cell.center.x - UIScreen.main.bounds.width/2 - self.collectionView!.contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }
            
        }
        return self.collectionView!.indexPath(for: closestCell)
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
    
    // TODO: Move the following funcs to a delegate method
    open func didTapTextInput(_ contentBefore:String?, contentAfter:String?) {
        
    }
    
    open func didTapBackspace() {
        
    }
    // ^^^

}

// MARK: CollectionView FlowLayout

extension EmojiCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section == 0 || (section == 1 && type.assets?[0].count == 0) || type?.display == nil {
            return CGSize.zero
        }
        return CGSize(width: type?.display!.size!.width ?? 50, height: 5)
        
    }
    
    
    // Controls the spacing between the top, bottom, and middle leave left and right 0
    //public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        /*guard let selectedTypeDisplay = type?.display else {
            return UIEdgeInsets.zero
        }
        print(collectionView.frame.height)
        let iconSize: CGFloat = selectedTypeDisplay.size!.width
        var divider: CGFloat = CGFloat(selectedTypeDisplay.rows!) + 1
        var rows: CGFloat = CGFloat(selectedTypeDisplay.rows!)
        if !isPortrait {
            divider -= 1
            rows -= 1
        }
        let verticalPadding = (self.collectionView!.bounds.height - (iconSize * rows) ) / divider
        return UIEdgeInsetsMake(verticalPadding, 0, verticalPadding, 0)*/
        //return customInsets
        
    //}
    
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
        
//        guard let display = type?.display
//            else {
//                return 5
//        }
//        
//        let iconSize: CGFloat = display.size!.width
//        var divider: CGFloat = CGFloat(display.rows!) + 1
//        var rows: CGFloat = CGFloat(display.rows!)
//        
//        if !isPortrait {
//            divider -= 1
//            rows -= 1
//        }
//        
//        let verticalPadding = (self.collectionView!.bounds.height - (iconSize * rows) ) / divider
//        if isPortrait {
//            return verticalPadding
//        } else {
//            return 120
//        }
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard type?.display?.size != nil else {
            return CGSize(width: 50, height: 50)
        }
        
        if isPortrait {
            var shortDimension = collectionView.bounds.height
            if WKConfig.sharedInstance.emojiCollectionViewDirection == "vertical" {
                shortDimension = collectionView.bounds.width
            }
            let dimension = shortDimension * 0.95 / numberOfRows
            return CGSize(width: dimension, height: dimension)
        }
        
        let collectionViewHeight = collectionView.frame.height * 0.95 / numberOfRows
        return CGSize(width: collectionViewHeight, height: collectionViewHeight)
        
    }
}
