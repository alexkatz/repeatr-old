//
//  TracksLoopRecordCollectionViewLayout.swift
//  Repeatr
//
//  Created by Alexander Katz on 10/21/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class TracksLoopRecordCollectionViewLayout: TracksCollectionViewLayout {

  private var armedCellIndexPath: IndexPath?
  
  required convenience init(bounds: CGSize, armedCellIndexPath: IndexPath? = nil) {
    self.init(bounds: bounds)
    self.armedCellIndexPath = armedCellIndexPath
  }
  
  override func prepare() {
    if let cellCount = self.collectionView?.numberOfItems(inSection: 0) {
      self.layoutAttributes.removeAll()
      for i in 0..<cellCount {
        let indexPath = IndexPath(item: i, section: 0)
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let cellSize = CGSize(width: self.bounds.width, height: Constants.cellHeight)
        let x = CGFloat(0)
        let y = CGFloat(0)
        
        layoutAttributes.frame = CGRect(
          origin: CGPoint(
            x: x,
            y: y),
          size: cellSize)
        
        if let armedCellIndexPath = self.armedCellIndexPath {
          layoutAttributes.alpha = armedCellIndexPath.item == indexPath.item ? 1 : 0
        }
        
        self.layoutAttributes.append(layoutAttributes)
      }
    }
  }
  
}
