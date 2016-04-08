//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {
  
  private lazy var label: UILabel = LayoutHelper.createInfoLabel()
  
  var waveformView: WaveformView? {
    didSet {
      oldValue?.removeFromSuperview()
      if let waveformView = self.waveformView {
        self.addWaveformView(waveformView)
      }
    }
  }
  
  var title: String? {
    didSet {
      self.label.text = self.title
      if self.title == nil {
        self.label.removeFromSuperview()
      } else {
        LayoutHelper.addInfoLabel(self.label, toView: self)
      }
    }
  }
  
  private func addWaveformView(waveformView: WaveformView) {
    waveformView.backgroundColor = UIColor.blackColor()
    waveformView.translatesAutoresizingMaskIntoConstraints = false
    
    self.addSubview(waveformView)
    
    waveformView.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor).active = true
    waveformView.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor).active = true
    waveformView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    waveformView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
  }
  
}
