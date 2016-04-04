//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class WaveformCollectionViewCell: UICollectionViewCell {
  
  var waveformView: WaveformView!
  
  lazy var label: UILabel = { [unowned self] in
    let label = UILabel()
    label.textColor = UIColor.whiteColor()
    label.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(label)
    
    label.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
    label.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
    
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.layoutWaveformView()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.layoutWaveformView()
  }
  
  var title: String? {
    didSet {
      self.label.text = self.title
    }
  }
  
  private func layoutWaveformView() {
    self.waveformView = WaveformView()
    self.waveformView.waveColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
    self.waveformView.cursorColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
    self.waveformView.bookmarkColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
    self.waveformView.bookmarkBaseColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
    self.waveformView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.waveformView)
    
    self.waveformView.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor).active = true
    self.waveformView.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor).active = true
    self.waveformView.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    self.waveformView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
  }
  
}
