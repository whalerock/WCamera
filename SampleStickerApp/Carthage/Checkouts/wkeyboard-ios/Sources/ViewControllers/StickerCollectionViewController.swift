//
//  StickerCollectionViewController.swift
//  ellenmoji
//
//  Created by David Hoofnagle on 9/6/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import UIKit
import Messages
import WKeyboard

private let reuseIdentifier = "StickerCollectionViewCell"


public protocol StickerCollectionViewControllerDelegate: class {
    func didCopyAsset (asset: WKAsset)
}

@available(iOSApplicationExtension 10.0, *)
open class StickerCollectionViewController: UICollectionViewController {

    public var type: WKType? {
        didSet {
            if type != nil {
                self.collectionView?.visibleCells.forEach({ (cell) in
                    cell.prepareForReuse()
                })
                self.collectionView?.reloadData {
                    self.collectionView?.collectionViewLayout.invalidateLayout()
                }
            }
        }
    }
    public var stickerSize: MSStickerSize = .regular
    weak public var delegate: StickerCollectionViewControllerDelegate?
    var lastScrollOffset: CGPoint = .zero

    public var padding = CGFloat(10.0)

    public var didScroll: ((_ scrollView: UIScrollView) -> ())?
    public var didEndScroll: ((_ scrollView: UIScrollView) -> ())?
    public var scrollWillBeginDragging: ((_ scrollView: UIScrollView) -> ())?
    public var scrollDidEndAnimatingScroll: ((_ scrollView: UIScrollView) -> ())?
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.collectionView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        // Wow this is messy
        guard let dele = delegate as? MessagesViewController else {
            return
        }
        guard let tabBarVC = dele.toolbarViewController else {
            return
        }
        guard let categoryCollectionView = dele.categoryCollectionViewController?.collectionView else {
            return
        }
        lastScrollOffset = CGPoint(x: 0, y: -(categoryCollectionView.bounds.height + tabBarVC.view.bounds.height))
        self.collectionView?.contentOffset = lastScrollOffset
        self.collectionView?.reloadData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = 10.0
            flowLayout.minimumLineSpacing = 10.0
            flowLayout.sectionInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        }


        self.collectionView?.contentOffset = lastScrollOffset
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lastScrollOffset = self.collectionView?.contentOffset ?? .zero
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("deinited stickerCollectionViewController")
    }
    
    func reanimateCellsIfNecessary() {
        self.collectionView?.reloadData {
        }
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
         didScroll?(scrollView)
    }
    
    open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollWillBeginDragging?(scrollView)
    }

    open override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollDidEndAnimatingScroll?(scrollView)
    }

    open func numberOfItems(inSection: Int) -> Int? {
        return self.collectionView?.numberOfItems(inSection: inSection)
    }

    open func selectItem(at: IndexPath, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        self.collectionView?.selectItem(at: at, animated: animated, scrollPosition: scrollPosition)
    }

    /**
     * numerOfSections
     */
    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let assets = type?.assets else {
            return 0
        }
        return assets.count
    }
    

    /**
     * numberOfItemsInSection
     */
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let assets = type?.assets else {
            return 0
        }
        return assets[section].count
    }

    /**
     * cellForItemAt
     */
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = type?.assets?[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stickerCell", for: indexPath) as! StickerCollectionViewCell
        cell.asset = asset
        
        return cell
    }
  
    public func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: self.view.bounds.width, height: 1)
    }

    /**
     * willDisplay
     */
    open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let animatedCell = cell as? StickerCollectionViewCell {
            animatedCell.startAnimatingIfAnimatable()
        }
    }

    /**
     * didEndDisplaying
     */
    open override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let animatedCell = cell as? StickerCollectionViewCell {
            animatedCell.stopAnimatingIfAnimatable()
            cell.prepareForReuse()
        }
        
    }

}

@available(iOSApplicationExtension 10.0, *)
extension StickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screen = UIScreen.main.bounds

        let availWidth = screen.width - 30

        var len = (availWidth - 3*10)/4
        switch stickerSize {
        case .small:
            len = (availWidth - 3*10)/4
        case .regular:
            len = (availWidth - 2*10)/3
        case .large:
            len = (availWidth - 10)/2
        }

        return CGSize(width: len, height: len)
    }
}

@available(iOSApplicationExtension 10.0, *)
extension StickerCollectionViewController: StickerCollectionViewCellDelegate {
    
    open func didTapCell(asset: WKAsset) {
        delegate?.didCopyAsset(asset: asset)
    }
}
