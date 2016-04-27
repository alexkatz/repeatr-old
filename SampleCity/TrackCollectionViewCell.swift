//
//  WaveformCollectionViewCell.swift
//  SampleCity
//
//  Created by Alexander Katz on 4/3/16.
//  Copyright © 2016 Alexander Katz. All rights reserved.
//

import UIKit

class TrackCollectionViewCell: UICollectionViewCell, PlaybackVisualDelegate {
  
  private lazy var label: UILabel = LayoutHelper.createInfoLabel()
  private lazy var volumeControlView: VolumeControlView = self.createVolumeControlView()
  private lazy var trackControlsView: UIView = self.createTrackControlsView()
  private lazy var playbackView: LoopPlaybackView = self.createPlaybackView()
  
  private var bottomSelectedBorder: UIView!
  private var topSelectedBorder: UIView!
  
  var track: Track? {
    didSet {
      oldValue?.waveformView.removeFromSuperview()
      self.trackControlsView.alpha = (self.active || self.track?.waveformView.audioURL == nil) ? 0 : 1
      if let track = self.track {
        self.addWaveformView(track.waveformView)
        self.bringSubviewToFront(self.volumeControlView)
        
        self.volumeControlView.delegate = track
        self.volumeControlView.volumeLevel = track.volumeLevel
      }
    }
  }
  
  var active = false {
    didSet {
      if let track = self.track {
        self.volumeControlView.volumeLevel = track.volumeLevel
        
        if !self.active {
          self.playbackView.trackService = track.trackService
          track.trackService.loopPlaybackDelegate = self.playbackView
          self.bringSubviewToFront(self.trackControlsView)
        }
      }
      self.track?.waveformView.enabled = self.active
      self.trackControlsView.alpha = (self.active || self.track?.waveformView.audioURL == nil) ? 0 : 1
    }
  }
  
  var enabled = true {
    didSet {
      self.track?.waveformView.enabled = self.enabled
    }
  }
  
  var selectedForLoopRecord = false {
    didSet {
      self.track?.waveformView.backgroundColor = self.selectedForLoopRecord ? Constants.blackSelectedColor : Constants.blackColor
    }
  }
  
  private func setSelectedBordersVisible(visible: Bool) {
    if self.bottomSelectedBorder == nil {
      
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
  
  private func createTrackControlsView() -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(view)
    
    view.rightAnchor.constraintEqualToAnchor(self.rightAnchor).active = true
    view.leftAnchor.constraintEqualToAnchor(self.leftAnchor).active = true
    view.topAnchor.constraintEqualToAnchor(self.topAnchor).active = true
    view.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    
    view.alpha = 0
    
    return view
  }
  
  private func createPlaybackView() -> LoopPlaybackView {
    let playbackView = LoopPlaybackView()
    playbackView.translatesAutoresizingMaskIntoConstraints = false
    self.trackControlsView.addSubview(playbackView)
    
    playbackView.heightAnchor.constraintEqualToAnchor(nil, constant: CGFloat(Constants.recordButtonHeight)).active = true
    playbackView.widthAnchor.constraintEqualToAnchor(self.trackControlsView.widthAnchor, multiplier: 0.25).active = true
    playbackView.leadingAnchor.constraintEqualToAnchor(self.trackControlsView.leadingAnchor).active = true
    playbackView.bottomAnchor.constraintEqualToAnchor(self.trackControlsView.bottomAnchor).active = true
    playbackView.enabled = true
    playbackView.visualDelegate = self
    
    return playbackView
  }
  
  private func createVolumeControlView() -> VolumeControlView {
    let volumeView = VolumeControlView()
    volumeView.translatesAutoresizingMaskIntoConstraints = false
    self.trackControlsView.addSubview(volumeView)
    
    volumeView.rightAnchor.constraintEqualToAnchor(self.trackControlsView.rightAnchor).active = true
    volumeView.heightAnchor.constraintEqualToAnchor(self.trackControlsView.heightAnchor).active = true
    volumeView.bottomAnchor.constraintEqualToAnchor(self.trackControlsView.bottomAnchor).active = true
    volumeView.leftAnchor.constraintEqualToAnchor(self.trackControlsView.leftAnchor).active = true
    volumeView.backgroundColor = Constants.whiteColor.colorWithAlphaComponent(0)
    volumeView.fillColor = Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
    volumeView.centerLabelText = nil
    return volumeView
  }
  
  // PlaybackVisualDelegate
  
  func playbackView(playbackView: LoopPlaybackView, isPlayingLoop: Bool) {
    self.volumeControlView.fillColor = isPlayingLoop ? Constants.greenColor.colorWithAlphaComponent(Constants.dimAlpha) : Constants.whiteColor.colorWithAlphaComponent(Constants.dimAlpha)
  }
}
