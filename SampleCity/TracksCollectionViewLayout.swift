//
//  TracksCollectionViewLayout.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/24/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import UIKit

class TracksCollectionViewLayout: UICollectionViewLayout {
  
  fileprivate let cellBottomBorder = CGFloat(2)
  
  var layoutAttributes = [UICollectionViewLayoutAttributes]()
  var bounds: CGSize!
  
  required convenience init(bounds: CGSize) {
    self.init()
    self.bounds = bounds
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return self.layoutAttributes.filter { layoutAttributes in
      rect.intersects(layoutAttributes.frame)
    }
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let layoutAttributes = self.layoutAttributes.filter({ layoutAttributes in
      (layoutAttributes.indexPath as NSIndexPath).item == (indexPath as NSIndexPath).item
    }).first
    
    return layoutAttributes
  }
  
  override var collectionViewContentSize : CGSize {
    if let cellCount = self.collectionView?.numberOfItems(inSection: 0) {
      let width = self.bounds.width
      let height = (CGFloat(cellCount) * Constants.cellHeight) + (CGFloat(cellCount) * self.cellBottomBorder)
      return CGSize(width: width, height: height)
    }
    
    return CGSize.zero
  }
  
  override func prepare() {
    if let cellCount = self.collectionView?.numberOfItems(inSection: 0) {
      self.layoutAttributes.removeAll()
      for i in 0..<cellCount {
        let indexPath = IndexPath(item: i, section: 0)
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let cellSize = CGSize(width: self.bounds.width, height: Constants.cellHeight)
        let x = CGFloat(0)
        let y = cellSize.height * CGFloat(i) + (self.cellBottomBorder * CGFloat(i))

        layoutAttributes.frame = CGRect(
          origin: CGPoint(
            x: x,
            y: y),
          size: cellSize)
        
        self.layoutAttributes.append(layoutAttributes)
      }
    }
  }
  
}
