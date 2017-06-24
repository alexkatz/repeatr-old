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
      let height = self.bounds.height
      let width = self.bounds.width * CGFloat(cellCount)
      return CGSize(width: width, height: height)
    }
    
    return CGSize.zero
  }
  
  override func prepare() {
    if let cellCount = self.collectionView?.numberOfItems(inSection: 0) {
      for i in 0..<cellCount {
        let indexPath = IndexPath(item: i, section: 0)
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let cellSize = self.bounds
        let x = (cellSize?.width)! * CGFloat(i)
        let y = CGFloat(0)
        
        layoutAttributes.frame = CGRect(
          origin: CGPoint(
            x: x,
            y: y),
          size: cellSize!)
        
        self.layoutAttributes.append(layoutAttributes)
      }
    }
  }
  
}
