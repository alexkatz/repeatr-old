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
//  private lazy var volumeControlView: VolumeControlView = self.createVolumeControlView()
  
  var track: Track? {
    didSet {
      oldValue?.waveformView.removeFromSuperview()
//      self.volumeControlView.alpha = (self.active || self.track?.waveformView.audioURL == nil) ? 0 : 1
      if let track = self.track {
        self.addWaveformView(track.waveformView)
//        self.bringSubviewToFront(self.volumeControlView)
//        self.volumeControlView.delegate = track
//        self.volumeControlView.volumeLevel = track.volumeLevel
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
  
  var active = false {
    didSet {
//      if let track = self.track {
//        self.volumeControlView.volumeLevel = track.volumeLevel
//      }
      self.track?.waveformView.enabled = self.active
//      self.volumeControlView.alpha = (self.active || self.track?.waveformView.audioURL == nil) ? 0 : 1
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
//  
//  private func createVolumeControlView() -> VolumeControlView {
//    let volumeView = VolumeControlView()
//    volumeView.translatesAutoresizingMaskIntoConstraints = false
//    self.addSubview(volumeView)
//    
//    volumeView.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
//    volumeView.heightAnchor.constraintEqualToAnchor(self.heightAnchor, multiplier: 0.5).active = true
//    volumeView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
//    volumeView.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
//    volumeView.alpha = 0
//    volumeView.backgroundColor = Constants.whiteColor.colorWithAlphaComponent(0.2)
//    volumeView.fillColor = Constants.whiteColor.colorWithAlphaComponent(0.4)
//    
//    return volumeView
//  }
}
