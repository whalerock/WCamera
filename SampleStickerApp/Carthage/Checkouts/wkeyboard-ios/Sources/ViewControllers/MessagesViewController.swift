//
//  MessagesViewController.swift
//  imessage
//
//  Created by David Hoofnagle on 8/25/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import UIKit
import Messages
import WConfig
import WNetwork
import WAssetManager
import WAnalytics
import WUtilities
import WKeyboard



public enum ViewState {
    case loading
    case downloadingContent
    case loaded
    case connectionRequired
}

@available(iOSApplicationExtension 10.0, *)
open class MessagesViewController: MSMessagesAppViewController {

    @IBOutlet weak var toolbarContainerView: UIView!
    @IBOutlet weak var categoryContainerView: UIView!

    var downloadViewController: DownloadViewController?
    var toolbarViewController: ToolBarViewController?
    var categoryCollectionViewController: CategoryCollectionViewController?
    var stickerCollectionViewController: StickerCollectionViewController?

    // State
    var assets: [WKAsset]?
    var categories = [WKCategory]()
    var selectedType: WKType?
    var isParsing = false
    var downloader: WNDownloader?
    var copiedAsset: WKAsset?

    // Customization
    // var kStickerExportSize = CGSize.zero
    let tintColor = UIColor(red: 64/255.0, green: 177/255.0, blue: 217/255.0, alpha: 1.0)
    let keyboardBackgroundColor = UIColor(red: 232/255.0, green: 249/255.0, blue: 255/255.0, alpha: 1.0)
    var shouldHighlightCategory = true

    override open func viewDidLoad() {
        super.viewDidLoad()
        //self.view.backgroundColor = UIColor.red

        // Try if config is already downloaded,
        self.parseStoredConfig()
        // else download config
        WKeyboard.api.fetchPayload {
            // and process
            self.parseStoredConfig()
        }
    }


    override open func viewWillDisappear(_ animated: Bool) {
        if self.downloader != nil {
            self.downloader?.queue?.cancelAllOperations()
            self.downloader = nil
        }

        super.viewWillDisappear(animated)

        let pb = UIPasteboard.general
        pb.setValue("", forPasteboardType: UIPasteboardName.general.rawValue)

        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        //self.notificationCenter.removeObserver(self)

    }

    override open func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.

        // Use this method to prepare for the change in presentation style.

        toolbarViewController?.selectedTabIndicator?.isHidden = true
    }

    override open func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.

        // Use this method to finalize any behaviors associated with the change in presentation style.
        //stickerCollectionViewController?.reanimateCellsIfNecessary()

        //let style = presentationStyle == .compact ? "compact" : "expanded"
        //WAnalytics.manager.trackEventGA("messages", action: "transitionedTo", label: style, customDimensions: nil, content: nil)

        toolbarViewController?.updateSelectorPosition()
    }


    func setState(state: ViewState, animated: Bool) {

        switch state {
        case .loading:
            print("loading")

        case .connectionRequired:
            _ = 1

        case .downloadingContent:
            addDownloadVC()

        case .loaded:
            print("loaded")
            // Replace downloader with stickerCollectionView
            self.removeDownloadVC()
            self.showStickerCollectionView()

        }

        print("State changed to \(state)")
    }

    func selectedTypeWasChanged() {
        guard selectedType?.title != nil else {
            print("selectedType: \(selectedType) is nil or has no title.")
            return
        }

        if stickerCollectionViewController?.view.isHidden == true {
            // Does this ever happen?
            stickerCollectionViewController?.view.isHidden = false
        }

        let animatedType = selectedType!.title!.lowercased().contains("gif") || selectedType!.title!.lowercased().contains("apng")
        if animatedType {
            // No category selector for gifs/apngs
            categoryContainerView.isHidden = true
            stickerCollectionViewController?.stickerSize = .large
        } else {
            categoryContainerView.isHidden = false
            stickerCollectionViewController?.stickerSize = .regular
            delay(0.2) {
                self.categoryCollectionViewController?.highlightCategory(at: IndexPath(row: 0, section: 0), withNotification: false)
            }
        }

        // Changing `type` triggers didSet and additional actions on VC
        stickerCollectionViewController?.type = selectedType
        categoryCollectionViewController?.type = selectedType

        //        if selectedType!.title!.lowercased().contains("gif") {
        //            stickerCollectionViewController?.stickerSize = .large
        //        } else if stickerType {
        //            stickerCollectionViewController?.stickerSize = .regular
        //        } else if emojiType {
        //            stickerCollectionViewController?.stickerSize = .small
        //        }

        if let numItems = stickerCollectionViewController?.numberOfItems(inSection: 0), numItems > 0 {
            stickerCollectionViewController!.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
        }

        //        self.view.bringSubview(toFront: toolbarContainerView)
        //        self.view.bringSubview(toFront: categoryContainerView)
    }


    func showStickerCollectionView() {
        // already created by storyboard (if no downloader)
        if stickerCollectionViewController != nil {
            return
            //            stickerCollectionViewController?.removeFromParentViewController()
            //            stickerCollectionViewController = nil
        }

        stickerCollectionViewController = self.storyboard?.instantiateViewController(withIdentifier: "StickerCollectionViewController") as? StickerCollectionViewController
        stickerCollectionViewController?.delegate = self

        self.addChildViewController(stickerCollectionViewController!)
        self.view.addSubview(stickerCollectionViewController!.view)
        //stickerCollectionViewController!.view.frame = self.view.bounds
        stickerCollectionViewController?.didScroll = { scrollView in
            self.scrollViewDidScroll(scrollView)
        }
        stickerCollectionViewController?.scrollWillBeginDragging = { scrollView in
            self.scrollViewWillBeginDragging(scrollView)
        }
        stickerCollectionViewController?.didEndScroll = { scrollView in
            self.scrollViewDidEndScrollingAnimation(scrollView)
        }
    }

    /**
     * update category as collection scrolls
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.categoryCollectionViewController?.selectedIndex != nil else {
            return
        }

        guard self.categoryCollectionViewController?.isMidSelection == false else {
            return
        }

        if let closestIndexPath = self.indexPathForClosestToMiddle() {
            // If selected category doesn't match middle sticker section #
            let middleItemCategoryIndex = (closestIndexPath as NSIndexPath).section
            if self.categoryCollectionViewController?.selectedIndex != middleItemCategoryIndex {
                // update category selected item
                let categoryIndexPath = IndexPath(item: middleItemCategoryIndex, section: 0)
                self.categoryCollectionViewController!.highlightCategory(at: categoryIndexPath, withNotification: false)
                self.categoryCollectionViewController!.collectionView?.scrollToItem(at: categoryIndexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.categoryCollectionViewController?.isMidSelection = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.categoryCollectionViewController?.isMidSelection = false
    }

    func indexPathForClosestToMiddle() -> IndexPath? {
        guard let stickersCollectionView = self.stickerCollectionViewController?.collectionView, stickersCollectionView.visibleCells.count > 0 else {
            return nil
        }

        let visibleCells = stickersCollectionView.visibleCells

        var closestCell : UICollectionViewCell = visibleCells[0];
        for cell in visibleCells {
            let closestCellDelta = abs(closestCell.center.y - UIScreen.main.bounds.height/2 - stickersCollectionView.contentOffset.y)
            let cellDelta = abs(cell.center.y - UIScreen.main.bounds.height/2 - stickersCollectionView.contentOffset.y)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }

        }
        return stickersCollectionView.indexPath(for: closestCell)
    }


    private func parseStoredConfig() {
        guard self.isParsing == false else {
            print("tried to parseStoredConfig, already parsing")
            return
        }

        if Thread.isMainThread {
            print("parseStoredConfig main")
        }

        WKeyboard.parser.parse { types, packs, categories, assetUrls in

            print("parser completion")

            guard types != nil, packs != nil, categories != nil, assetUrls != nil else {
                print("parser some items not found, config not loaded")
                self.isParsing = false
                return
            }

            self.categories = categories!

            guard self.downloader == nil else {
                DispatchQueue.main.async {
                    self.setState(state: .downloadingContent, animated: true)
                }
                print("parser downloader already working")
                return
            }

            print("parsing!")
            self.isParsing = true
            self.downloadAssets(types!, packs!, categories!, assetUrls!) {
                // Check the file size assets and remove any that are too large
                WKeyboard.parser.storedAssets?.forEach { asset in
                    if let assetUrl = asset.assetUrl {
                        if let localFilePath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: assetUrl) {
                            if let sizekB = WAssetManager.sharedInstance.sizeOfLocalFile(localFilePath) {
                                if sizekB > 500.0 {
                                    print("file too large!: \(sizekB) kB")

                                    // remove from WKParser asset list, but DON'T delete local asset to prevent redownload on each load
                                    WKeyboard.parser.pruneAsset(withURL: assetUrl)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func downloadAssets(_ types: [WKType], _ packs: [WKPack], _ categories: [WKCategory], _ assets: [String], completionHandler:@escaping ()->()) {
        let doneDownload = {
            self.isParsing = false

            // This causes toolbar to appear
            self.toolbarViewController?.types = types
            if types.indices.contains(0) {
                self.selectedType = types[0]
            }

            // ***************** SET STATE
            self.setState(state: .loaded, animated: false)
            self.selectedTypeWasChanged()
            delay (0.3) {
                self.toolbarViewController?.setSelectedIndex(0)
            }
            // Free downloader
            self.downloader = nil

            completionHandler()
        }

        func downloadProgress(savedAssetPath: String?, progress: Double) {
            print("download progress")
            guard savedAssetPath != nil else {
                return
            }

            // verify item was downloaded
            if let localAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: savedAssetPath!) {
                print(progress, localAssetPath)

                guard self.downloadViewController != nil else {
                    return
                }

                DispatchQueue.main.async {
                    // Stop slowConnectionTimer, clear statusLabel text
                    self.downloadViewController?.slowConnectionTimer?.invalidate()
                    self.downloadViewController?.statusLabel?.text = ""

                    // Update progress
                    self.downloadViewController?.progressView?.progress = Float(progress)

                    // Update preview image
                    if !localAssetPath.contains("gif") && !localAssetPath.contains("apng") {
                        if let imgData = try? Data(contentsOf: URL(fileURLWithPath: localAssetPath)) {
                            if let img = UIImage(data: imgData) {
                                //let img = self.resizeImage(atPath: localAssetPath)
                                self.downloadViewController?.assetPreview?.image = nil
                                self.downloadViewController?.assetPreview?.image = img
                            }
                        }
                    }
                }
            }
        }

        if assets.count > 0 {
            if !WNetwork.manager.hasConnection() {
                print("can't download assets, no connection. Really??")
                // ***************** SET STATE
                self.setState(state: .connectionRequired, animated: false)
                return
            }
            print("downloading assets")
            // ***************** SET STATE
            self.setState(state: .downloadingContent, animated: true)

            self.downloader = WNDownloader(maxConncurrent: 5000)
            self.downloader?.download(assets, progressHandler: downloadProgress, completionHandler: {
                print("downloader completion handler")
                doneDownload()
            })
        } else {
            print("no assets, nothing to download")
            doneDownload()
        }
    }

    func addDownloadVC() {
        if downloadViewController == nil {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_DownloadViewController") as? DownloadViewController {
                downloadViewController = vc
            }
            self.addChildViewController(downloadViewController!)
            downloadViewController!.view.frame = self.view.bounds
            self.view.addSubview(downloadViewController!.view)
        }
    }

    func removeDownloadVC() {
        if downloadViewController != nil {
            downloadViewController!.view.removeFromSuperview()
            downloadViewController!.removeFromParentViewController()
            downloadViewController = nil
        }
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CategoryCollectionViewController {
            vc.delegate = self
            categoryCollectionViewController = vc
            self.view.bringSubview(toFront: categoryCollectionViewController!.view)
        }
        if let vc = segue.destination as? ToolBarViewController {
            toolbarViewController = vc
            toolbarViewController!.delegate = self
            self.view.bringSubview(toFront: toolbarViewController!.view)
        }
        if let vc = segue.destination as? StickerCollectionViewController {
            // TODO this seems duplicated above in showStickerCollectionView()
            stickerCollectionViewController = vc
            stickerCollectionViewController?.delegate = self
            stickerCollectionViewController?.didScroll = { scrollView in
                self.scrollViewDidScroll(scrollView)
            }
            stickerCollectionViewController?.scrollWillBeginDragging = { scrollView in
                self.scrollViewWillBeginDragging(scrollView)
            }
            stickerCollectionViewController?.didEndScroll = { scrollView in
                self.scrollViewDidEndScrollingAnimation(scrollView)
            }
        }
    }
}


@available(iOSApplicationExtension 10.0, *)
extension MessagesViewController: ToolbarViewControllerDelegate {

    public func toolBarDidChangeType(sender: UIButton) {
        self.categoryCollectionViewController?.isMidSelection = true

        if let type = WKManager.sharedInstance.types?[sender.tag] {
            selectedType = type
            guard selectedType?.title != nil else {
                return
            }

            selectedTypeWasChanged()

            if let typeTitle = type.title {
                WAnalytics.manager.sendEvent(.messages, action: .tap, label: typeTitle)
            }
        }
    }

}

@available(iOSApplicationExtension 10.0, *)
extension MessagesViewController: CategoryViewControllerDelegate {

    public func closeToneSelector(animated: Bool) {

    }

    public func shouldScrollToCategory(_ category: WKCategory, at indexPath: IndexPath) {
        guard let collectionView = stickerCollectionViewController?.collectionView else { return }

        if let categoryTitle = category.title {
            WAnalytics.manager.sendEvent(.messages, action: .tap, label: categoryTitle)
        }

        let index = IndexPath(row: indexPath.section, section: indexPath.row)

        if index.item == 0 {
            let ypos = -collectionView.contentInset.top
            collectionView.setContentOffset(CGPoint(x: 0, y: ypos), animated: false)
            return
        }

        if let attributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
            let topOfHeader = CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.contentInset.top)
            collectionView.setContentOffset(topOfHeader, animated: false)
        }
    }

}


@available(iOSApplicationExtension 10.0, *)
extension MessagesViewController: StickerCollectionViewControllerDelegate {
    public func didCopyAsset (asset: WKAsset) {
        copiedAsset = asset
    }
}
