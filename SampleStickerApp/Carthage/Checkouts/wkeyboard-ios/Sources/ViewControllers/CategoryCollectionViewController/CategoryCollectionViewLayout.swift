//
//  CategoryCollectionViewLayout.swift
//  WKeyboard
//
//  Created by David Hoofnagle on 1/13/17.
//  Copyright © 2017 Whalerock Industries. All rights reserved.
//

import UIKit

class CategoryCollectionViewLayout: UICollectionViewLayout {
    
    public var categoryCount: CGFloat = 0
    var contentWidth: CGFloat = 0
    var yPosition: CGFloat = 0
    var interitemSpacing: CGFloat = 0
    var collectionWidth: CGFloat = 0
    
    override var collectionViewContentSize: CGSize {
        get {
            return CGSize(width: collectionWidth, height: collectionView!.bounds.height)
        }
    }
    
    func sizeforItem() -> CGSize {
        let f: CGFloat = 0.80
        return CGSize(width: collectionView!.bounds.height * f, height: collectionView!.bounds.height * f)
    }
    
    override func prepare() {
        super.prepare()

        let cellHeight = sizeforItem().height
        let cellWidth = sizeforItem().width
        let numOfItems =  CGFloat(collectionView!.numberOfItems(inSection: 0))

        collectionWidth = numOfItems * (cellWidth + interitemSpacing + 1)
        interitemSpacing = 20.0
        yPosition = (collectionView!.bounds.height - cellHeight) / 2
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var elementsInRect = [UICollectionViewLayoutAttributes]()
        //iterate over all cells in this collection
        for i in 0..<collectionView!.numberOfItems(inSection: 0) {
            
            //this is the cell at row i
            let xPosition: CGFloat = interitemSpacing + CGFloat(i)*(interitemSpacing+sizeforItem().width)
            let cellFrame = CGRect(x: xPosition, y: yPosition, width: sizeforItem().width, height: sizeforItem().height)
            
            if cellFrame.intersects(rect) {
                //create the attributes object
                let indexPath = IndexPath(item: i, section: 0)
                let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attr.frame = cellFrame
                elementsInRect.append(attr)
            }
        }
        return elementsInRect
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let i = indexPath.item
        let xPosition: CGFloat = interitemSpacing + CGFloat(i)*(interitemSpacing+sizeforItem().width)
        let cellFrame = CGRect(x: xPosition, y: yPosition, width: sizeforItem().width, height: sizeforItem().height)
        attr.frame = cellFrame
        
        return attr
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
