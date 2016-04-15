//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class TrackCollectionViewCell: UICollectionViewCell {
  
  private lazy var label: UILabel = LayoutHelper.createInfoLabel()

  var track: Track? {
    didSet {
      oldValue?.waveformView.removeFromSuperview()
      if let track = self.track {
        self.addWaveformView(track.waveformView)
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
