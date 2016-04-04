//
//  WaveformCollectionViewLayout.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/4/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import Foundation
import UIKit

class WaveformCollectionViewLayout: UICollectionViewLayout {
  
  var layoutAttributes = [UICollectionViewLayoutAttributes]()
  var bounds: CGSize!
  
  required convenience init(bounds: CGSize) {
    self.init()
    self.bounds = bounds
  }
  
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return self.layoutAttributes.filter { layoutAttributes in
      CGRectIntersectsRect(rect, layoutAttributes.frame)
    }
  }
  
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    let layoutAttributes = self.layoutAttributes.filter({ layoutAttributes in
      layoutAttributes.indexPath.item == indexPath.item
    }).first
    
    return layoutAttributes
  }
  
  override func collectionViewContentSize() -> CGSize {
    if let cellCount = self.collectionView?.numberOfItemsInSection(0) {
      let height = self.bounds.height
      let width = self.bounds.width * CGFloat(cellCount)
      return CGSize(width: width, height: height)
    }
    
    return CGSize.zero
  }
  
  override func prepareLayout() {
    if let cellCount = self.collectionView?.numberOfItemsInSection(0) {
      for i in 0..<cellCount {
        let indexPath = NSIndexPath(forItem: i, inSection: 0)
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        let cellSize = self.bounds
        let x = cellSize.width * CGFloat(i)
        let y = CGFloat(0)
        
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