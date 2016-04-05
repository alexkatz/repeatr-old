//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {
  
  var waveformView: WaveformView? {
    willSet {
      if let waveformView = self.waveformView {
        waveformView.removeFromSuperview()
      }
    }
    didSet {
      if let waveformView = self.waveformView {
        self.addWaveformView(waveformView)
      }
    }
  }
  
  lazy var label: UILabel = { [unowned self] in
    let label = UILabel()
    label.textColor = Constants.whiteColor
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Constants.font
    self.addSubview(label)
    
    label.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    label.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
    
    return label
    }()
  
  var title: String? {
    didSet {
      self.label.text = self.title
      self.label.alpha = self.title != nil ? 1 : 0
      if self.title == nil {
        self.waveformView = nil
      }
    }
  }
  
  private func addWaveformView(waveformView: WaveformView) {
    waveformView.translatesAutoresizingMaskIntoConstraints = false
    
    self.addSubview(waveformView)
    
    waveformView.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor).active = true
    waveformView.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor).active = true
    waveformView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    waveformView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
  }
  
}
